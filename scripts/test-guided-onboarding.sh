#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK="$(GO_STACK="${GO_STACK:-}" bash "$ROOT/scripts/bootstrap-stack.sh")"
export GO_STACK="$STACK" PYTHONDONTWRITEBYTECODE=1
unset GO_STACK_ALLOW_DEV
"${PYTHON:-python3}" - "$ROOT" "$STACK" <<'PY'
import hashlib,json,os,subprocess,sys,tempfile
from pathlib import Path

root=Path(sys.argv[1]);stack=Path(sys.argv[2])
env={**os.environ,'PYTHON':sys.executable,'PATH':str(Path(sys.executable).parent)+os.pathsep+os.environ['PATH']}
def call(args,cwd,env=env,ok=True):
    p=subprocess.run(list(map(str,args)),cwd=cwd,env=env,text=True,capture_output=True,timeout=420)
    if ok: assert p.returncode==0,p.stdout+p.stderr
    return p
def git(repo,*args):return call(['git','-C',repo,*args],root).stdout.strip()
def read(path):return json.loads(path.read_text())
def write(path,data):path.write_text(json.dumps(data,indent=2)+'\n')
def hashes(path):return {str(p.relative_to(path)):hashlib.sha256(p.read_bytes()).hexdigest() for p in path.rglob('*') if p.is_file() and '.git' not in p.parts}
def go(repo,*args,env=env):return call([repo/'go',*args],repo,env).stdout

source=hashes(root/'.go');pin=read(root/'.go/project.json')['stack_ref']
commit=git(stack,'rev-parse',pin+'^{commit}')
assert git(stack,'rev-parse','HEAD')==commit and git(stack,'cat-file','-t','refs/tags/'+pin)=='tag'
sys.path.insert(0,str(stack))
from go_workflow.completion import lifecycle_report,read_artifact

with tempfile.TemporaryDirectory(prefix='go-guided-template-') as temp:
    temp=Path(temp);repo=temp/'project';remote=temp/'remote.git'
    # Clone the committed product tree, not local controller state or uncommitted edits.
    call(['git','clone','--quiet','--no-hardlinks',root,repo],temp)
    assert sorted(p.stem for p in (repo/'.go/tasks/open').glob('*.json'))==['task-schema-smoke']
    assert not list((repo/'.go/tasks/active').glob('*.json'))
    starter=read(repo/'.go/project.json')
    assert starter['project_mode']=='template' and 'execution_defaults' not in starter
    git(repo,'config','user.name','Guided fixture');git(repo,'config','user.email','guided@example.invalid')
    git(repo,'checkout','-B','main');call(['git','init','--bare','-q',remote],temp)
    git(repo,'remote','set-url','origin',str(remote))

    # Both a stale pin and stale rendered documentation must fail the current pairing check.
    pair=[sys.executable,stack/'cli/go.py','pairing','template','--template',repo,'--stack-repo',stack,'--json']
    call(pair,repo)
    for path,old,new in [(repo/'README.md',commit,'0'*40),(repo/'.go/project.json',pin,'v999.0.0')]:
        original=path.read_bytes();assert old.encode() in original
        path.write_bytes(original.replace(old.encode(),new.encode(),1))
        assert call(pair,repo,ok=False).returncode!=0
        path.write_bytes(original)

    (repo/'VERSION').write_text('1.1.0\n')
    before=hashes(repo)
    unresolved=json.loads(go(repo,'onboarding','plan',repo,'--json'))
    assert unresolved['status']=='needs_configuration' and unresolved['settings'] is None
    assert {'model','publisher','verification','deployment'} <= {q['field'] for q in unresolved['questions']}
    assert hashes(repo)==before

    answers=read(repo/'examples/abc/onboarding-answers.example.json')
    answers.update(model={'id':'gpt-6-astra','effort':'medium'},base_branch='main',
        verification=["python3 -c \"from pathlib import Path; assert Path('app.txt').read_text() == 'two\\n'; assert Path('VERSION').read_text().strip() == '1.2.0'\""],
        publisher={'provider':'git-tag','remote':'origin'},version={'path':'VERSION','format':'text'},
        bump='minor',tag_prefix='v',changelog='CHANGELOG.md',
        deployment={'mode':'none','reason':'Disposable local Git release test'},
        task={'id':'first-release','summary':'Write app.txt with two followed by a newline',
              'scope':{'read':['app.txt'],'modify':['app.txt']},
              'acceptance':['app.txt contains two and the required release is verified']})
    answer_path=temp/'answers.json';write(answer_path,answers)
    plan=json.loads(go(repo,'onboarding','plan',repo,'--answers',answer_path,'--json'))
    assert plan['status']=='ready' and not plan['questions'] and hashes(repo)==before
    settings=temp/'settings.json';brief=temp/'brief.json'
    write(settings,plan['settings']);write(brief,plan['execution_brief'])
    assert 'allow_push' not in json.dumps(plan['settings'])
    go(repo,'adopt',repo,'--force','--project-id','guided-template-fixture','--name','Guided fixture','--lifecycle-settings',settings)
    actual=read(repo/'.go/project.json')
    assert actual['project_mode']=='project' and 'dependency_projects' not in actual
    assert actual['release_profiles']==plan['settings']['release_profiles']
    assert not list((repo/'.go/evidence').glob('*history*'))
    assert not list((repo/'.go/tasks/open').glob('*.json'))
    go(repo,'recommendation','create',repo,'--brief',brief,'--authority','execute','--authority-source','imperative')
    go(repo,'go',repo,'--write','--json')
    task=read(repo/'.go/tasks/open/first-release.json')
    assert task['status']=='open' and not task['claim']['agent']
    assert all(o['status']=='pending' and not o['evidence'] for o in task['requested_outcomes'])
    assert task['scope']['modify']==['app.txt','VERSION','CHANGELOG.md']
    assert task['verification']==answers['verification']
    git(repo,'add','.');git(repo,'commit','-qm','Explicit guided project and first task')
    git(repo,'tag','-a','v1.1.0','-m','Baseline');git(repo,'push','origin','main','refs/tags/v1.1.0')

    binary_dir=temp/'bin';binary_dir.mkdir();binary=binary_dir/'codex'
    binary.write_text('#!'+sys.executable+'\n'+(stack/'fixtures/abc-campaign/worker.py').read_text());binary.chmod(0o755)
    capture=temp/'workers.jsonl';worker=temp/'worker'
    runenv={**env,'PATH':str(binary_dir)+os.pathsep+env['PATH'],'ABC_CAMPAIGN_CAPTURE':str(capture)}
    result=json.loads(go(repo,'auto',repo,'--execute','--task-id','first-release','--agent','fixture',
        '--executor-agent','codex','--max-commands','30','--max-minutes','5','--workspace-path',worker,
        '--workspace-branch','task/first','--base-branch','main','--base-commit',git(repo,'rev-parse','HEAD'),
        '--run-id','first-run','--ship-policy','push','--allow-push','--json',env=runenv))
    assert result['status'] in {'done','task_complete'},result
    done=read(repo/'.go/tasks/done/first-release.json')
    assert done['review_status']=='approved' and done['release_receipt']['tag']=='v1.2.0'
    report=lifecycle_report(repo);assert report['evidence_valid']
    proof=read_artifact(repo/'.go',done['completion_evidence']['verification'])
    assert proof['status']=='passed' and proof['content_unchanged']
    calls=[json.loads(line) for line in capture.read_text().splitlines()]
    assert [c['phase'] for c in calls]==['build','critic'] and len({c['cwd'] for c in calls})==1
    assert not worker.exists()
    release_commit=git(repo,'rev-parse','v1.2.0^{commit}')
    assert git(repo,'ls-remote','origin','refs/tags/v1.2.0^{}').startswith(release_commit)
    assert hashes(root/'.go')==source
    print(json.dumps({'schema':'go-workflow.guided-template-proof.v1','status':'passed',
        'source_commit':git(root,'rev-parse','HEAD'),'runtime_commit':commit,
        'model_execution':'deterministic native CLI double; no model calls',
        'source_state_unchanged':True,'stale_pairings_rejected':True,'settings_and_intake':'real CLI',
        'task':'first-release','tag':'v1.2.0','release_commit':release_commit,
        'receipt':done['release_receipt'],'verification':proof},indent=2))
print('TEMPLATE_GUIDED_ALL_PASSED')
PY
