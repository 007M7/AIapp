// Store full-resolution cropped images as blobs, not base64 in localStorage.
const DB='xiaojing-wallpaper',STORE='images',KEY='chat';
function open(){return new Promise((resolve,reject)=>{const req=indexedDB.open(DB,1);req.onupgradeneeded=()=>{if(!req.result.objectStoreNames.contains(STORE))req.result.createObjectStore(STORE)};req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error)})}
async function run(mode,action){const db=await open();return new Promise((resolve,reject)=>{let result;const tx=db.transaction(STORE,mode);const req=action(tx.objectStore(STORE));req.onsuccess=()=>{result=req.result};tx.oncomplete=()=>{db.close();resolve(result)};tx.onerror=()=>{db.close();reject(tx.error)};tx.onabort=()=>{db.close();reject(tx.error)}})}
export const loadWallpaper=()=>run('readonly',store=>store.get(KEY));
export const saveWallpaper=blob=>run('readwrite',store=>store.put(blob,KEY));
export const deleteWallpaper=()=>run('readwrite',store=>store.delete(KEY));
