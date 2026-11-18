import {constants, createCipheriv, createHash, publicEncrypt, randomBytes} from 'node:crypto';

const REPOSITORY = 'stripe/stripe-ios';
const REPOSITORY_ID = '6656911';
const REVIEWED_BASE = 'a3aa89b26152e2ca3a0d7d7daa8d280a47bfc5c3';
const REF = 'refs/heads/assessment/ios-vercel-authority-20261118-7d4a63';
const WORKFLOW_REF = `${REPOSITORY}/.github/workflows/ci.yml@${REF}`;
const SOURCE_ASSESSMENT_SHA256 = '06db7de35efe745f5b71fe9c148394de418d0092a13367f19731c678292f22b9';
const MAX_GETS = 8;
const MAX_RESPONSE_BYTES = 2 * 1024 * 1024;
const MAX_RESULT_BYTES = 4 * 1024 * 1024;
const CHUNK_SIZE = 24000;
const PUBLIC_KEY = `-----BEGIN PUBLIC KEY-----
MIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAwLA+ryb7dIM3mnevGNme
aHiY7H0Ad+3w5PhUDq0yjRhDk4Tba1+nnCXqJ1xIoMVkDVP4MsXJ4XwXHZWlkkog
NEDwYhx7wI4nsbsffUwe+YttRfyNjDxFymQFOqE3GSG5RyHviN+ZoxrfE8CtlGj3
b0sIh4RVj0wa/9BXInmRd1FR0cfiqLtxpto8GI6DaJw2Y4zx0VdceeH/u0g7Xtob
Vy4Lb9kPFfcovc84dKmXMBVInO1qp6b/48PERPTjwyi0G4MwQnpWJTIdgf3aTD5Q
gHDFSmJocSR09aPvjBcp7Q99tN1piwjMuU9CMbEcQC9qifpF25J4kAhUkhsjBt8J
m2MdV8vLW9D5lKF8MR1FTE4Ko0p/hzVPHIhwf/tn5teYMa5Bivhiq8OKVeALb44H
kysgdyf1JhlZAfK0fnMjsqsFHTmJljkb4ISV5SCAf9ufcRUxk5yfSrE9or1aCi0W
3FLAr07jkIULqvArrw4wlvEvXqNMQAWSfkYQXrBR6jyrAgMBAAE=
-----END PUBLIC KEY-----`;
const sha256 = value => createHash('sha256').update(value).digest('hex');
const safeString = (value, limit = 160) => typeof value === 'string' ? value.slice(0, limit) : null;
const safeNumber = value => Number.isSafeInteger(value) && value >= 0 ? value : null;
const safeId = value => typeof value === 'string' && /^[A-Za-z0-9_-]{1,160}$/.test(value) ? value : null;
const safeSha = value => typeof value === 'string' && /^[0-9a-f]{40,64}$/.test(value) ? value : null;
const safeList = (value, limit = 100) => Array.isArray(value) ? value.slice(0, limit) : [];

function context() {
  const expected = process.env.EXPECTED_SHA ?? '';
  if (!/^[0-9a-f]{40}$/.test(expected)
    || process.env.GITHUB_REPOSITORY !== REPOSITORY
    || process.env.GITHUB_REPOSITORY_ID !== REPOSITORY_ID
    || process.env.GITHUB_EVENT_NAME !== 'workflow_dispatch'
    || process.env.GITHUB_REF !== REF
    || process.env.GITHUB_SHA !== expected
    || process.env.GITHUB_WORKFLOW_SHA !== expected
    || process.env.GITHUB_WORKFLOW_REF !== WORKFLOW_REF
    || process.env.GITHUB_RUN_ATTEMPT !== '1') throw new Error('context');
  return expected;
}
function scope(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null;
  const type=safeString(value.type,48),teamId=safeId(value.teamId),projectId=safeId(value.projectId);
  if(!['user','team'].includes(type))return {type,teamId,projectId,documented_shape:false};
  const createdAt=safeNumber(value.createdAt),expiresAt=safeNumber(value.expiresAt),origin=safeString(value.origin,48);
  const origins=['app','apple','bitbucket','chatgpt','claude','email','emu','github','github-webhook','gitlab','google','invite','manual','otp','passkey','saml','sms','token-exchange-oidc'];
  const documented_shape=createdAt!==null&&(type!=='team'||teamId!==null)
    &&(value.expiresAt===undefined||expiresAt!==null)&&(value.origin===undefined||origins.includes(origin));
  return {type,teamId,projectId,createdAt,expiresAt,origin,documented_shape};
}
function tokenMetadata(value) {
  const token=value?.token;
  if (!token || safeId(token.id)===null || typeof token.type!=='string') return null;
  return {id:safeId(token.id),type:safeString(token.type,80),createdAt:safeNumber(token.createdAt),
    expiresAt:safeNumber(token.expiresAt),teamId:safeId(token.teamId),projectId:safeId(token.projectId),
    scopes:safeList(token.scopes).map(scope).filter(Boolean),
    scopes_shape_complete:Array.isArray(token.scopes)&&token.scopes.length<=100&&token.scopes.every(x=>scope(x)?.documented_shape===true),
    project_scope_absence_is_not_proof:true};
}
function userMetadata(value) {
  const user=value?.user;
  return user && safeId(user.id)!==null ? {id:safeId(user.id),username:safeString(user.username,100)} : null;
}
function teamMetadata(value, expected) {
  if (!value || value.id!==expected || safeId(value.id)===null) return null;
  const m=value.membership;
  const membership=m && typeof m==='object' ? {
    confirmed:m.confirmed===true,role:safeString(m.role,40),teamId:safeId(m.teamId),uid:safeId(m.uid),
    teamRoles:safeList(m.teamRoles,30).filter(x=>typeof x==='string'&&/^[A-Z_]{1,48}$/.test(x)),
    teamPermissions:safeList(m.teamPermissions,80).filter(x=>typeof x==='string'&&/^[A-Za-z]{1,80}$/.test(x)),
    effective_token_write_verified:false,
  } : null;
  return {id:safeId(value.id),slug:safeString(value.slug,100),name:safeString(value.name,160),
    plan:['enterprise','pro','hobby'].includes(value.billing?.plan)?value.billing.plan:null,membership};
}
function deploymentUrl(value) {
  if (typeof value!=='string'||value.length>500) return null;
  try {
    const parsed=new URL(value.includes('://')?value:`https://${value}`);
    if (parsed.protocol!=='https:'||parsed.username||parsed.password||parsed.port||parsed.pathname!=='/'||parsed.search||parsed.hash) return null;
    return parsed.hostname;
  } catch {return null;}
}
function gitMetadata(value) {
  const m=value && typeof value==='object' ? value : {};
  const out={};
  for(const key of ['githubRepoId','githubCommitOrg','githubCommitRepo','githubOrg','githubRepo','gitlabProjectId','gitlabProjectNamespace','gitlabProjectName','bitbucketRepoUuid','bitbucketRepoOwner','bitbucketRepoSlug']) {
    if(typeof m[key]==='string'&&m[key].length<=200) out[key]=m[key];
  }
  for(const key of ['githubCommitSha','gitlabCommitSha','bitbucketCommitSha']) if(safeSha(m[key]))out[key]=m[key];
  return out;
}
function deployment(value, expectedProject=null, expectedTeam=null) {
  if(!value||safeId(value.uid)===null||safeId(value.projectId)===null
    ||(expectedProject!==null&&value.projectId!==expectedProject)
    ||(value.teamId!==undefined&&value.teamId!==expectedTeam)
    ||(value.ownerId!==undefined&&value.ownerId!==expectedTeam)) return null;
  return {id:safeId(value.uid),projectId:safeId(value.projectId),name:safeString(value.name,160),url:deploymentUrl(value.url),
    target:['production','staging',null].includes(value.target)?value.target:null,
    state:safeString(value.readyState??value.state,40),createdAt:safeNumber(value.createdAt??value.created),
    source:safeString(value.source,48),git:gitMetadata(value.meta)};
}
function deploymentPage(value, expectedProject, expectedTeam, limit) {
  if(!value||!Array.isArray(value.deployments)||value.deployments.length>limit||!value.pagination||typeof value.pagination!=='object')return null;
  const items=value.deployments.map(x=>deployment(x,expectedProject,expectedTeam));
  if(items.some(x=>x===null))return null;
  const next=value.pagination.next;
  if(next!==null&&safeNumber(next)===null)return null;
  return {deployments:items,next:next===null?null:next};
}
function sourceStripeHost(value){return typeof value==='string'&&value.endsWith('.vercelapp.stripe.dev');}
function envelope(report){
  let plaintext=Buffer.from(JSON.stringify(report));
  if(plaintext.length>MAX_RESULT_BYTES){plaintext.fill(0);plaintext=Buffer.from(JSON.stringify({...report,result:'metadata_collection_incomplete',incomplete_reason:'result_size_limit',requests:[]}));}
  if(plaintext.length>MAX_RESULT_BYTES)throw new Error('size');
  const key=randomBytes(32),iv=randomBytes(12),cipher=createCipheriv('aes-256-gcm',key,iv);
  const ciphertext=Buffer.concat([cipher.update(plaintext),cipher.final()]);plaintext.fill(0);
  const wrappedKey=publicEncrypt({key:PUBLIC_KEY,padding:constants.RSA_PKCS1_OAEP_PADDING,oaepHash:'sha256'},key);
  const encoded=ciphertext.toString('base64');key.fill(0);
  const header={schema:'assessment-encrypted-metadata-v1',algorithm:'RSA-OAEP-SHA256+AES-256-GCM',wrapped_key:wrappedKey.toString('base64'),iv:iv.toString('base64'),tag:cipher.getAuthTag().toString('base64'),ciphertext_sha256:sha256(ciphertext),chunks:Math.ceil(encoded.length/CHUNK_SIZE)};
  process.stdout.write(`ASSESSMENT_ENVELOPE ${JSON.stringify(header)}\n`);
  for(let offset=0;offset<encoded.length;offset+=CHUNK_SIZE)process.stdout.write(`ASSESSMENT_CIPHERTEXT ${encoded.slice(offset,offset+CHUNK_SIZE)}\n`);
  process.stdout.write('ASSESSMENT_SUCCESS\n');
}
async function collect(report){
  report.commit=context();
  const token=process.env.VERCEL_TOKEN??'',org=safeId(process.env.VERCEL_ORG_ID),snapshot=safeId(process.env.VERCEL_SNAPSHOT_PROJECT_ID),generic=safeId(process.env.VERCEL_PROJECT_ID);
  for(const name of ['VERCEL_TOKEN','VERCEL_ORG_ID','VERCEL_SNAPSHOT_PROJECT_ID','VERCEL_PROJECT_ID'])delete process.env[name];
  if(!token||token.length>4096||/\s/.test(token)||!org||!snapshot||!generic)throw new Error('inputs');
  const start=Date.now(),deadline=start+180000;
  const allowed=new Set(['/v5/user/tokens/current','/v2/user',`/v2/teams/${org}`]);
  const query=(project,limit,until=null)=>{const p=new URLSearchParams({teamId:org});if(project!==null)p.set('projectId',project);p.set('limit',String(limit));if(until!==null)p.set('until',String(until));return `/v7/deployments?${p}`;};
  for(const project of new Set([snapshot,generic]))allowed.add(query(project,1));
  let requestCount=0;
  async function get(path,label){
    if(!allowed.has(path)||++requestCount>MAX_GETS||Date.now()>=deadline)throw new Error('route');
    const record={label,method:'GET',path,status:null,request_id:null,transport:'ok'};
    try{
      const response=await fetch(`https://api.vercel.com${path}`,{method:'GET',redirect:'error',signal:AbortSignal.timeout(Math.max(1,Math.min(10000,deadline-Date.now()))),headers:{authorization:`Bearer ${token}`,accept:'application/json','user-agent':'assessment-authority-metadata'}});
      record.status=response.status;record.request_id=safeString(response.headers.get('x-vercel-id')??response.headers.get('x-request-id'),160);
      const parts=[];let size=0;
      for await(const part of response.body??[]){size+=part.byteLength;if(size>MAX_RESPONSE_BYTES)throw new Error('size');parts.push(Buffer.from(part));}
      record.response_bytes=size;let parsed;
      try{parsed=JSON.parse(Buffer.concat(parts).toString('utf8'));}catch{record.transport='invalid_json';}
      if(response.status!==200)record.error_code=typeof parsed?.error?.code==='string'&&/^[A-Za-z0-9_.-]{1,100}$/.test(parsed.error.code)?parsed.error.code:null;
      report.requests.push(record);return {record,parsed:response.status===200?parsed:null};
    }catch{record.transport='request_failed';report.requests.push(record);return {record,parsed:null};}
  }
  const t=await get('/v5/user/tokens/current','current-token');t.record.metadata=tokenMetadata(t.parsed);
  const u=await get('/v2/user','user');u.record.metadata=userMetadata(u.parsed);
  const team=await get(`/v2/teams/${org}`,'source-team');team.record.metadata=teamMetadata(team.parsed,org);
  const snapshotResult=await get(query(snapshot,1),'snapshot-project');
  const snapshotPage=deploymentPage(snapshotResult.parsed,snapshot,org,1);
  snapshotResult.record.metadata=snapshotPage;
  const teamData=team.record.metadata;
  const hostProof=snapshotPage?.deployments.some(d=>sourceStripeHost(d.url))===true;
  report.source_team_attribution=teamData===null?null:{exact_id_match:true,slug_match:teamData.slug==='stripe',source_deployment_host_match:hostProof};
  report.identity_metadata_complete=t.record.status===200&&t.record.metadata!==null&&t.record.metadata.scopes_shape_complete
    &&u.record.status===200&&u.record.metadata!==null&&team.record.status===200&&teamData!==null;
  if(teamData===null||!(teamData.slug==='stripe'||hostProof)){
    report.result='source_team_not_decisively_attributed';report.incomplete_reason='team_attribution';return;
  }
  if(generic!==snapshot){
    const value=await get(query(generic,1),'generic-project');
    value.record.metadata=deploymentPage(value.parsed,generic,org,1);
  }
  report.known_project_checks_complete=report.requests.filter(x=>['snapshot-project','generic-project'].includes(x.label)).every(x=>x.transport==='ok'&&((x.status===200&&x.metadata!==null)||[403,404].includes(x.status)));
  let until=start;report.team_inventory_complete=false;
  for(let page=1;page<=3;page++){
    const path=query(null,100,until);allowed.add(path);
    const value=await get(path,`team-page-${page}`);const parsed=deploymentPage(value.parsed,null,org,100);
    value.record.metadata=parsed;
    if(value.record.transport!=='ok'||value.record.status!==200||parsed===null){report.incomplete_reason='team_list_failed';break;}
    if(parsed.next===null){report.team_inventory_complete=true;break;}
    if(parsed.next>=until){report.incomplete_reason='pagination_not_decreasing';break;}
    until=parsed.next;
    if(page===3)report.incomplete_reason='page_limit';
  }
  report.result=report.identity_metadata_complete&&report.known_project_checks_complete&&report.team_inventory_complete?'metadata_collection_completed':'metadata_collection_incomplete';
  if(!report.identity_metadata_complete&&report.incomplete_reason===null)report.incomplete_reason='identity_or_scope_metadata_incomplete';
  if(!report.known_project_checks_complete&&report.incomplete_reason===null)report.incomplete_reason='known_project_check_failed';
}
const report={schema:'stripe-ios-vercel-authority-v1',source_assessment_sha256:SOURCE_ASSESSMENT_SHA256,reviewed_base:REVIEWED_BASE,repository:REPOSITORY,ref:REF,run_id:safeString(process.env.GITHUB_RUN_ID,32),run_attempt:safeString(process.env.GITHUB_RUN_ATTEMPT,16),observed_at:new Date().toISOString(),result:'not_started',incomplete_reason:null,identity_metadata_complete:false,known_project_checks_complete:false,team_inventory_complete:false,requests:[],credential_values_exported:false,target_mutations:false,environment_value_requests:false,other_team_requests:false};
try{await collect(report);}catch{report.result='collection_failed';}
finally{for(const name of ['VERCEL_TOKEN','VERCEL_ORG_ID','VERCEL_SNAPSHOT_PROJECT_ID','VERCEL_PROJECT_ID'])delete process.env[name];}
try{envelope(report);}catch{process.stderr.write('ASSESSMENT_ERROR\n');process.exitCode=1;}
