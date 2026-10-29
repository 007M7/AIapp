export function cropToOriginal(rect,previewWidth,previewHeight,originalWidth,originalHeight){
 if(!previewWidth||!previewHeight||!originalWidth||!originalHeight||!rect||rect.w<=0||rect.h<=0)throw new Error('invalid crop');
 const x=Math.max(0,Math.min(originalWidth-1,Math.floor(rect.x*originalWidth/previewWidth)));
 const y=Math.max(0,Math.min(originalHeight-1,Math.floor(rect.y*originalHeight/previewHeight)));
 const right=Math.max(x+1,Math.min(originalWidth,Math.ceil((rect.x+rect.w)*originalWidth/previewWidth)));
 const bottom=Math.max(y+1,Math.min(originalHeight,Math.ceil((rect.y+rect.h)*originalHeight/previewHeight)));
 return {x,y,width:right-x,height:bottom-y};
}
