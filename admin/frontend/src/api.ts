export type Kind='asset'|'character'|'content'|'event';
export type Role='admin'|'editor'|'reviewer'|'publisher'|'operator'|'viewer';
export interface User{id:string;username:string;role:Role;csrf:string;preview_only?:number}
export interface Revision{id:string;object_id:string;number:number;name:string;kind:Kind;state:string;created_by:string;creator:string;created_at:string;review_note:string|null;payload:Record<string,string|number>}
export interface Release{id:string;name:string;manifest:Array<{revision_id:string;object_id:string;kind:Kind;name:string;number:number;payload:Revision['payload']}>;created_at:string}
export interface Audit{id:number;username:string;action:string;target:string;outcome:string;details:Record<string,unknown>;created_at:string;request_id:string}
export interface Execution{id:string;status:string;created_at:string;result:{text:string;character:string;asset_digest:string;device_played:boolean;scope:string}}
export interface State{user:User;preview:boolean;permissions:string[];objects:Array<{id:string;kind:Kind;name:string;head:number}>;revisions:Revision[];releases:Release[];channels:Array<{name:string;release_id:string|null}>;history:Array<{id:number;channel:string;release_id:string|null;action:string;created_at:string}>;executions:Execution[];audit:Audit[];audit_next:number;users:Array<{id:string;username:string;role:Role;enabled:number;preview_only:number}>}
export class ApiError extends Error {constructor(public status:number,public code:string,message:string){super(message)}}
let csrf='';
const retryKeys=new Map<string,string>();
export function setCSRF(value:string){csrf=value}
export async function api<T>(path:string,body?:unknown,key?:string):Promise<T>{
 const encoded=body===undefined?undefined:JSON.stringify(body);
 const fingerprint=encoded===undefined?'':Array.from(new Uint8Array(await crypto.subtle.digest('SHA-256',new TextEncoder().encode(path+encoded)))).map(x=>x.toString(16).padStart(2,'0')).join('');
 const requestKey=key||retryKeys.get(fingerprint)||crypto.randomUUID();if(encoded!==undefined)retryKeys.set(fingerprint,requestKey);
 const res=await fetch(path,{method:body===undefined?'GET':'POST',credentials:'same-origin',headers:body===undefined?{}:{'Content-Type':'application/json','X-Admin-CSRF':csrf,'Idempotency-Key':requestKey},body:encoded});
 const data=await res.json();if(res.status<500)retryKeys.delete(fingerprint);if(!res.ok||!data.ok)throw new ApiError(res.status,data.error?.code||'ERROR',data.error?.message||'请求失败');return data.data;
}
export const write=<T=unknown>(action:string,body:unknown,key?:string)=>api<T>('/api/admin/'+action,body,key);
