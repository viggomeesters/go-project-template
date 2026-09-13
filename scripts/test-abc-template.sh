#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STACK="$(GO_STACK="${GO_STACK:-}" bash "$ROOT/scripts/bootstrap-stack.sh")"
export GO_STACK="$STACK" PYTHONDONTWRITEBYTECODE=1
# Exact pinned runtime required for the clone campaign; never inherit a development override.
unset GO_STACK_ALLOW_DEV
"${PYTHON:-python3}" - "$ROOT" "$STACK" <<'PY'
import copy,hashlib,importlib.util,json,os,shutil,subprocess,sys,tempfile
from pathlib import Path
root=Path(sys.argv[1]);stack=Path(sys.argv[2]);env={**os.environ,'PYTHON':sys.executable,'PATH':str(Path(sys.executable).parent)+os.pathsep+os.environ['PATH']}
def call(args,cwd,env=env):
 p=subprocess.run(list(map(str,args)),cwd=cwd,env=env,text=True,capture_output=True,timeout=600)
 assert p.returncode==0,p.stdout+p.stderr
 return p.stdout

def git(repo,*args):return call(['git','-C',repo,*args],root).strip()
def read(p):return json.loads(p.read_text())
def write(p,d):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(d,indent=2)+'\n')
def hashes(path):return {str(p.relative_to(path)):hashlib.sha256(p.read_bytes()).hexdigest() for p in path.rglob('*') if p.is_file()}
source=hashes(root/'.go');smoke=(root/'.go/tasks/open/task-schema-smoke.json').read_bytes()
project=read(root/'.go/project.json');assert project['project_mode']=='template' and 'execution_defaults' not in project
assert sorted(p.stem for p in (root/'.go/tasks/open').glob('*.json'))==['task-schema-smoke']
assert not list((root/'.go/tasks/active').glob('*.json'))
pin=git(stack,'rev-parse',project['stack_ref']+'^{commit}');assert git(stack,'rev-parse','HEAD')==pin
assert git(stack,'cat-file','-t','refs/tags/'+project['stack_ref'])=='tag'
sys.path.insert(0,str(stack))
from go_workflow.completion import lifecycle_report,read_artifact,CompletionError
from go_workflow.release import publication_profile
from go_workflow.cli import validate_repo
from go_workflow.worktrees import integration_slot,WorkspaceError
spec=importlib.util.spec_from_file_location('campaign',stack/'fixtures/abc-campaign/campaign.py');campaign=importlib.util.module_from_spec(spec);spec.loader.exec_module(campaign)
live=read(stack/'.go/evidence/abc-10-live/manifest.json');assert live['status']=='passed'
for name,digest in live['successful_source']['files_sha256'].items():assert hashlib.sha256((stack/name).read_bytes()).hexdigest()==digest
results=[]
with tempfile.TemporaryDirectory(prefix='go-template-abc-') as temp:
 temp=Path(temp);runtime=temp/'runtime';linked_runtime=temp/'linked runtime'
 call(['git','clone','--quiet','--no-checkout',stack,runtime],temp);git(runtime,'checkout','--detach','--quiet',pin)
 git(runtime,'worktree','add','--quiet','--detach',linked_runtime,pin)
 call(['make','-C',root,'check'],temp,{**env,'GO_STACK':str(linked_runtime)})
 binary_dir=temp/'bin';binary_dir.mkdir();binary=binary_dir/'codex';binary.write_text('#!'+sys.executable+'\n'+(stack/'fixtures/abc-campaign/worker.py').read_text());binary.chmod(0o755)
 for mode,chosen_runtime in [('ordinary',runtime),('linked',linked_runtime)]:
  case=temp/mode;case.mkdir();backing=case/'backing';repo=case/'project';remote=case/'remote.git';capture=case/'workers.jsonl'
  call(['git','clone','--quiet','--no-hardlinks',root,repo],case)
  assert (repo/'.git').is_dir()
  assert sorted(p.stem for p in (repo/'.go/tasks/open').glob('*.json'))==['task-schema-smoke']
  git(repo,'config','user.name','Template fixture');git(repo,'config','user.email','template-fixture@example.invalid')
  git(repo,'checkout','-B','main')
  call(['git','init','--bare','-q',remote],case);git(repo,'remote','set-url','origin',str(remote))
  runenv={**env,'GO_STACK':str(chosen_runtime),'PATH':str(binary_dir)+os.pathsep+env['PATH'],'ABC_CAMPAIGN_CAPTURE':str(capture)}
  assert call([repo/'go','version'],repo,runenv).strip()==project['required_stack_version']
  settings=read(root/'examples/abc/lifecycle-settings.example.json')
  settings['execution_defaults']['model']=campaign.PROFILES[0]
  settings['execution_defaults']['critic_model']=campaign.PROFILES[1]
  settings['execution_defaults']['workspace']['base_branch']='main'
  settings['release_profiles']['project-release'].update(remote='origin',branch='main')
  settings['default_verification']=['git diff --check']
  for phase in settings['phase_profiles']['standard']:
   phase['scope']['read']=['.go/**','app.txt','VERSION','CHANGELOG.md']
   phase['scope']['modify']=['app.txt'] if phase['id'] in ['build','repair'] else ['VERSION','CHANGELOG.md'] if phase['id']=='release' else []
  config=case/'settings.json';write(config,settings)
  call([repo/'go','spike',repo,'--project-id','template-campaign-'+mode,'--name','Template fixture','--brief','Two explicit local task releases','--task','campaign-1|Deliver local step one','--epic','delivery|Local release proof','--target-epic','delivery','--execution-mode','agent','--verification','git diff --check','--skip-repo-complete','--lifecycle-settings',config],repo,runenv)
  actual=read(repo/'.go/project.json');assert actual['project_mode']=='project' and 'dependency_projects' not in actual
  assert actual['release_profiles']==settings['release_profiles']
  assert not (repo/'.go/evidence/abc-template-01-history').exists()
  override=case/'model.json';write(override,{'model':campaign.PROFILES[1]})
  dependency=case/'dependency.json';write(dependency,[{'project':actual['id'],'task_id':'campaign-1','requires':'done_with_required_release_evidence'}])
  call([repo/'go','task','create',repo,'--id','campaign-2','--summary','Deliver local step two','--epic','delivery','--execution-mode','agent','--shareable-delivery','none','--read','.go/**','--read','app.txt','--modify','app.txt','--modify','VERSION','--modify','CHANGELOG.md','--acceptance','Deliver step two with release proof','--verification','git diff --check','--execution-contract',override,'--dependencies',dependency],repo,runenv)
  # Refine generated scope/checks before claim, as prescribed by Go plan after onboarding.
  for index in [1,2]:
   p=repo/f'.go/tasks/open/campaign-{index}.json';task=read(p);expected='one\n' if index==1 else 'two\n'
   assert task['claim']['agent'] is None and all(o['status']=='pending' for o in task['requested_outcomes'])
   task.update(order=index,shareable_delivery='none',description='Write only app.txt with '+repr(expected)+'. The controller owns canonical state, VERSION/CHANGELOG and publication. Critic checks the current candidate and returns the adapter verdict; no subagents.',scope={'read':['.go/**','app.txt','VERSION','CHANGELOG.md'],'modify':['app.txt','VERSION','CHANGELOG.md']},verification=[f"python3 -c \"from pathlib import Path; assert Path('app.txt').read_text() == {expected!r}; assert Path('VERSION').read_text().strip() == '1.{index+1}.0'\""],acceptance=[f'app.txt contains {expected!r} and release v1.{index+1}.0 is proven'])
   task['requested_outcomes']=[{'id':'R1','text':task['acceptance'][0],'source':'template-fixture','status':'pending','evidence':[]}];write(p,task)
  configured_bytes=(repo/'.go/project.json').read_bytes()
  missing=read(repo/'.go/project.json');missing['release_profiles']['project-release'].pop('remote');write(repo/'.go/project.json',missing)
  try:publication_profile(repo,read(repo/'.go/tasks/open/campaign-1.json'))
  except CompletionError as error:assert 'missing' in str(error)
  else:raise AssertionError('missing release destination accepted')
  assert not capture.exists()
  (repo/'.go/project.json').write_bytes(configured_bytes)
  (repo/'VERSION').write_text('1.1.0\n');(repo/'CHANGELOG.md').write_text('# Local template campaign\n')
  git(repo,'add','.');git(repo,'commit','-qm','customize fresh template with two explicit lifecycle tasks');git(repo,'tag','-a','v1.1.0','-m','baseline');git(repo,'push','origin','main','refs/tags/v1.1.0')
  before=hashes(repo/'.go');call([repo/'go','migrate',repo,'--lifecycle','--config',config,'--json'],repo,runenv);assert hashes(repo/'.go')==before
  blocked=campaign.run_task(repo,'campaign-2',runtime=chosen_runtime,env=runenv,expected_blocked=True);assert not blocked['completed_tasks'] and not capture.exists()
  if mode=='linked':
   view=case/'unregistered-linked-view';git(repo,'worktree','add','--quiet','--detach',view,'HEAD')
   assert (view/'.git').is_file() and call([view/'go','version'],view,runenv).strip()==project['required_stack_version']
   primary_before=hashes(repo/'.go')
   refused=campaign.run_task(view,'campaign-1',runtime=chosen_runtime,env=runenv,commands=1,expected_blocked=True)
   assert refused['status']=='resume_gate' and 'primary control checkout' in refused['summary'] and not capture.exists()
   assert hashes(repo/'.go')==primary_before
  first=campaign.run_task(repo,'campaign-1',runtime=chosen_runtime,env=runenv,commands=1)
  assert first['status']=='budget_exhausted' and first['phase']=='release_prepare',first
  state=read(repo/'.go/runs/campaign-1/run-state.json');assert (repo.parent/'campaign-1-worker').exists()
  # A real unmerged Git index must survive a rejected integration attempt byte-for-byte.
  owned=repo.parent/'campaign-1-worker';app=(owned/'app.txt').read_bytes()
  assert (owned/'.git').is_file() and call([owned/'go','version'],owned,runenv).strip()==project['required_stack_version']
  assert call([owned/'go','readback',owned],owned,runenv)==call([repo/'go','readback',repo],repo,runenv)
  oid=git(owned,'hash-object','-w','app.txt')
  index_info=''.join(f'100644 {oid} {stage}\tapp.txt\n' for stage in [1,2,3])
  subprocess.run(['git','update-index','--index-info'],cwd=owned,input=index_info,text=True,check=True)
  unmerged=git(owned,'ls-files','--unmerged');assert unmerged
  try:
   with integration_slot(repo,'campaign-1','campaign-owner','campaign-1-run'):raise AssertionError('unmerged workspace accepted')
  except WorkspaceError:pass
  assert git(owned,'ls-files','--unmerged')==unmerged and (owned/'app.txt').read_bytes()==app
  assert not git(repo,'ls-remote','origin','refs/tags/v1.2.0')
  git(owned,'reset','-q','HEAD','--','app.txt')  # Restore only this disposable fixture's synthetic index entries.
  continued=campaign.run_task(repo,'campaign-1',runtime=chosen_runtime,env=runenv,initial=False)
  assert continued['completed_tasks']==['campaign-1'],continued
  assert read(repo/'.go/runs/campaign-1/run-state.json')['run_id']==state['run_id']
  second=campaign.run_task(repo,'campaign-2',runtime=chosen_runtime,env=runenv)
  assert second['completed_tasks']==['campaign-2'],second
  report=lifecycle_report(repo);assert report['evidence_valid'] and not validate_repo(repo)
  calls=[json.loads(line) for line in capture.read_text().splitlines()];one=[c for c in calls if c['task_id']=='campaign-1']
  assert [c['phase'] for c in one]==['build','critic','repair','critic']
  assert 'forced critic finding C1' in json.dumps(one[2]['feedback'])
  details=[]
  for index in [1,2]:
   tid=f'campaign-{index}';done=read(repo/f'.go/tasks/done/{tid}.json');task_calls=[c for c in calls if c['task_id']==tid]
   assert len({c['cwd'] for c in task_calls})==1
   assert done['release_receipt']['tag']==f'v1.{index+1}.0' and done['review_status']=='approved'
   proof=read_artifact(repo/'.go',done['completion_evidence']['verification']);assert proof['status']=='passed' and proof['content_unchanged']
   for c in task_calls:
    model=campaign.PROFILES[1] if c['phase']=='critic' else campaign.PROFILES[index-1];argv=c['argv']
    assert argv[argv.index('--model')+1]==model['id'] and 'model_reasoning_effort='+json.dumps(model['effort']) in argv
   assert not (repo.parent/(tid+'-worker')).exists()
   tag=f'v1.{index+1}.0';commit=git(repo,'rev-parse',tag+'^{commit}');assert git(repo,'ls-remote','origin','refs/tags/'+tag+'^{}').startswith(commit)
   details.append({'task':tid,'tag':tag,'commit':commit,'model':done['execution_contract']['model'],'critic_model':done['execution_contract']['critic_model'],'receipt':done['release_receipt'],'verification':proof,'phases':[{k:c[k] for k in ['phase','cwd','context_ref']} for c in task_calls]})
  git(repo,'merge-base','--is-ancestor','v1.2.0^{commit}','v1.3.0^{commit}')
  before_tags=git(repo,'ls-remote','--tags','origin');before_calls=capture.read_bytes()
  again=campaign.run_task(repo,'campaign-2',runtime=chosen_runtime,env=runenv,initial=False)
  assert again['completed_tasks']==['campaign-2'] and git(repo,'ls-remote','--tags','origin')==before_tags and capture.read_bytes()==before_calls
  results.append({'mode':mode,'controller':'primary checkout','execution_workspace':'owned linked worktree','unregistered_linked_controller_rejected':mode=='linked','runtime_commit':pin,'model_execution':'deterministic native CLI double, no model calls','resumed_after':'build','task_releases':details,'idempotent_completion':True,'unmerged_integration_rejected_without_changes':True,'missing_release_destination_rejected':True})
 assert hashes(root/'.go')==source and (root/'.go/tasks/open/task-schema-smoke.json').read_bytes()==smoke
 git(runtime,'worktree','remove',linked_runtime)
print(json.dumps({'schema':'go-workflow.template-abc-proof.v1','status':'passed','cases':results,'live_evidence':'https://github.com/viggomeesters/go-workflow-stack/blob/v0.3.26/.go/evidence/abc-10-live/manifest.json','live_runtime_hashes_matched':len(live['successful_source']['files_sha256']),'source_state_unchanged':True},indent=2))
PY
# Reuse the released runtime's actual failure tests instead of copying its validators.
# They use local Git / fake publishers. Their internal development flags are isolated fixtures.
TMP_TEST="$(mktemp -d)"
trap 'rm -rf "$TMP_TEST"' EXIT
cd "$TMP_TEST"
PYTHONPATH="$STACK:$STACK/tests" uv run --no-project --python 3.12 --with 'pytest>=8,<9' --with 'jsonschema>=4.23' python -m pytest -q -p no:cacheprovider \
 "$STACK/tests/test_abc_release.py::test_lost_command_acknowledgement_reconciles_without_duplicate_effect" \
 "$STACK/tests/test_abc_release.py::test_github_create_lost_response_uses_readback_without_republication" \
 "$STACK/tests/test_abc_release.py::test_managed_release_resumes_budgeted_effects_and_cleans_separately" \
 "$STACK/tests/test_abc_resume.py::test_cleanup_retry_only_cleans_the_already_delivered_task" \
 "$STACK/tests/test_abc_worktrees.py::test_cleanup_failure_has_recovery_without_republishing_and_preserves_ignored_files" \
 "$STACK/tests/test_abc_end_to_end.py::test_conflicting_base_after_green_preserves_both_sides_without_release" \
 "$STACK/tests/test_abc_models.py::test_unknown_critic_model_blocks_before_build_writes" \
 "$STACK/tests/test_abc_models.py::test_changed_selection_is_rejected_between_phases" \
 "$STACK/tests/test_abc_release.py::test_unknown_github_response_is_never_treated_as_absence" \
 "$STACK/tests/test_abc_release.py::test_managed_conflicting_remote_preserves_explicit_resume_handoff" \
 "$STACK/tests/test_abc_migration.py::test_apply_rollback_idempotent_preserves_exact_historical_bytes" \
 "$STACK/tests/test_abc_migration.py::test_existing_override_survives_adoption_and_no_authority_keys_are_accepted" \
 "$STACK/tests/test_abc_migration.py::test_interrupted_apply_blocks_claim_and_resumes_exact_journal"
printf 'TEMPLATE_ABC_ALL_PASSED\n'
