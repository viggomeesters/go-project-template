#!/usr/bin/env python3
"""Read-only source assertions and disposable onboarding/runtime fixtures; no model calls."""
import copy
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

ROOT=Path(__file__).resolve().parents[2]
ENV={**os.environ,'PYTHON':sys.executable,'PYTHONDONTWRITEBYTECODE':'1'}
ENV.pop('GO_STACK_ALLOW_DEV',None)

def call(args,*,cwd=ROOT,env=ENV,ok=True):
    result=subprocess.run(list(map(str,args)),cwd=cwd,env=env,text=True,capture_output=True)
    if ok:assert result.returncode==0,result.stdout+result.stderr
    return result

def git(repo,*args):return call(['git','-C',repo,*args]).stdout.strip()
def write(p,d):p.write_text(json.dumps(d,indent=2)+'\n')
def tree(p):return {str(f.relative_to(p)):hashlib.sha256(f.read_bytes()).hexdigest() for f in p.rglob('*') if f.is_file() and '.git' not in f.parts}

stack=Path(call(['bash',ROOT/'scripts/bootstrap-stack.sh']).stdout.strip()).resolve()
sys.path.insert(0,str(stack))
from go_workflow.migrations import configured_project
from go_workflow.execution_contracts import validate_execution_contract
from go_workflow.cli import validate_task
project=json.loads((ROOT/'.go/project.json').read_text());assert project['project_mode']=='template' and 'execution_defaults' not in project
settings=json.loads((ROOT/'examples/abc/lifecycle-settings.example.json').read_text())
configured_project(project,settings)
example=json.loads((ROOT/'examples/abc/task.example.json').read_text());assert not validate_task(example,'example',expected_status='open')
assert {'VERSION','CHANGELOG.md'}<=set(example['scope']['modify'])
assert not validate_execution_contract(json.loads((ROOT/'examples/abc/model-override.example.json').read_text()),partial=True)
smoke=ROOT/'.go/tasks/open/task-schema-smoke.json';original=smoke.read_bytes();assert 'execution_contract' not in json.loads(original)
ref=project['stack_ref'];expected=git(stack,'rev-parse',ref+'^{commit}')
assert git(stack,'cat-file','-t','refs/tags/'+ref)=='tag'
with tempfile.TemporaryDirectory(prefix='go-abc-onboarding-') as tmp:
    tmp=Path(tmp);runtime=tmp/'runtime';linked=tmp/'linked runtime'
    call(['git','clone','--quiet','--no-hardlinks','--no-checkout',stack,runtime]);git(runtime,'checkout','--detach','--quiet',expected)
    git(runtime,'worktree','add','--quiet','--detach',linked,expected)
    assert (runtime/'.git').is_dir() and (linked/'.git').is_file()
    for candidate in [runtime,linked]:
        env={**ENV,'GO_STACK':str(candidate)}
        assert call([ROOT/'go','version'],env=env).stdout.strip()==project['required_stack_version']
        assert git(candidate,'rev-parse','HEAD')==expected
    # Reject a lightweight replacement even at the same commit; only this disposable clone is changed.
    tag_object=git(runtime,'rev-parse','refs/tags/'+ref)
    git(runtime,'update-ref','refs/tags/'+ref,expected)
    rejected=call([ROOT/'go','version'],env={**ENV,'GO_STACK':str(runtime)},ok=False)
    assert rejected.returncode!=0 and git(runtime,'rev-parse','HEAD')==expected
    git(runtime,'update-ref','refs/tags/'+ref,tag_object)
    git(runtime,'checkout','--detach','--quiet',expected+'^');before=git(runtime,'rev-parse','HEAD')
    result=call([ROOT/'go','version'],env={**ENV,'GO_STACK':str(runtime)},ok=False)
    assert result.returncode!=0 and 'pinned runtime' in result.stderr
    assert git(runtime,'rev-parse','HEAD')==before
    # A detached linked worktree keeps its own exact HEAD while the other checkout moves.
    assert call([ROOT/'go','version'],env={**ENV,'GO_STACK':str(linked)}).stdout.strip()==project['required_stack_version']
    git(runtime,'checkout','--detach','--quiet',expected)
    source=runtime/'cli/go.py';source.write_text(source.read_text()+'\n# fixture edit: preserve me\n');personal=runtime/'personal.txt';personal.write_text('user work')
    before_source=source.read_bytes()
    result=call([ROOT/'go','version'],env={**ENV,'GO_STACK':str(runtime)},ok=False)
    assert result.returncode!=0 and 'uncommitted changes' in result.stderr
    assert source.read_bytes()==before_source and personal.read_text()=='user work'
    customized=tmp/'customized';shutil.copytree(ROOT,customized,ignore=shutil.ignore_patterns('.git','.pytest_cache','.DS_Store','__pycache__'))
    cfg=copy.deepcopy(settings);cfg['execution_defaults']['model']={'id':'fixture-model','effort':'high'}
    cfg['execution_defaults']['workspace']['base_branch']='main';cfg['release_profiles']['project-release'].update(remote='origin',branch='main');cfg['default_verification']=['git diff --check']
    config=tmp/'settings.json';write(config,cfg)
    env={**ENV,'GO_STACK':str(linked)}
    call([customized/'go','spike',customized,'--project-id','customized-proof','--name','Customized Proof','--brief','Explicit fixture onboarding','--task','onboard|Review the newly generated task scope before execution','--execution-mode','agent','--verification','git diff --check','--skip-repo-complete','--lifecycle-settings',config,'--json'],env=env,cwd=customized)
    actual=json.loads((customized/'.go/project.json').read_text())
    assert actual['project_mode']=='project' and actual['id']=='customized-proof'
    assert actual['release_profiles']==cfg['release_profiles'] and 'dependency_projects' not in actual
    assert not (customized/'.go/architecture/briefs/abc-onboarding.json').exists()
    assert sorted(p.stem for p in (customized/'.go/tasks/open').glob('*.json'))==['onboard']
    assert not list((customized/'.go/tasks/done').glob('*.json'))
    override=tmp/'override.json';write(override,{'model':{'id':'fixture-second','effort':'medium'}})
    call([customized/'go','task','create',customized,'--id','deliver-release','--summary','Deliver a versioned app change','--epic','delivery','--execution-mode','agent','--read','.go/**','--read','app.py','--modify','app.py','--modify','tests/**','--modify','VERSION','--modify','CHANGELOG.md','--acceptance','The observable app behavior is verified before release','--verification','git diff --check','--execution-contract',override],env=env,cwd=customized)
    created=json.loads((customized/'.go/tasks/open/deliver-release.json').read_text())
    assert created['execution_contract']['model']=={'id':'fixture-second','effort':'medium'}
    assert created['execution_contract']['phase_profile']=='standard'
    assert created['execution_contract']['workspace']==cfg['execution_defaults']['workspace']
    assert all(item['status']=='pending' and not item['evidence'] for item in created['requested_outcomes'])
    assert created['claim']['agent'] is None and 'release_receipt' not in created
    before=tree(customized/'.go')
    call([customized/'go','migrate',customized,'--lifecycle','--config',config,'--json'],env=env,cwd=customized)
    assert tree(customized/'.go')==before
    call([customized/'go','validate',customized],env=env,cwd=customized)
    git(runtime,'worktree','remove',linked)
assert smoke.read_bytes()==original
print('ABC onboarding: examples, exact ordinary/linked runtimes, preservation, customization and pending intake passed; no model calls')
