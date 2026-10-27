export function deviceStateTitle(snapshot, {error='',micState='',posting=false}={}) {
  if(micState)return micState;
  if(posting)return '正在发送';
  if(error)return '等待状态更新';
  if(!snapshot)return '正在连接';
  if(!snapshot.device_online)return '未连接';
  if(snapshot.service_ready===false)return '暂时无法互动';
  const state=snapshot.telemetry_fresh?snapshot.telemetry?.state:null;
  if(state==='REC')return '正在听';
  if(state==='WAIT')return '处理中';
  if(state==='PLAY')return '正在回应';
  if(state==='ERR')return '暂时无法互动';
  if(snapshot.busy)return '互动进行中';
  return state==='IDLE'?'可互动':'等待状态更新';
}
export function operationTitle(operation,{posting=false,uncertain=false,snapshot=null}={}) {
  if(posting)return '正在发送，请稍候';
  if(operation?.status==='running'&&operation.kind==='voice') {
    const state=snapshot?.telemetry_fresh?snapshot.telemetry?.state:null;
    return state==='PLAY'?'手办正在回应':state==='WAIT'?'正在准备回答':'等待手办状态确认';
  }
  return {accepted:'服务器已受理',sent:'已发送，等待手办回执',running:'手办正在执行',
    completed:operation?.kind==='voice'?'回答已播放完毕':'手办已执行，请核对短鸣',
    rejected:'手办未执行',failed:'本次互动未完成，请重试',unknown:'结果未确认，不会自动重发'}[operation?.status] || (uncertain?'结果未确认，请查看手办；不会自动重发':'');
}
