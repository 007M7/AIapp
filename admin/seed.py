"""Explicit onboarding example; only allowed in local preview stores."""
import argparse
import base64
from pathlib import Path
from service import Store,uid
def seed(directory,image):
    store=Store(directory,True)
    with store.connection() as c:
        if c.execute('SELECT 1 FROM objects').fetchone():
            print('资料库已有内容，未重复创建样例');return
    users={r:store.login({'role':r},True,uid())[1] for r in ['editor','reviewer','publisher']}
    def write(action,body,role='editor'):return store.write(users[role],action,body,uid(),uid())
    def approve(result):
        write('submit',{'revision_id':result['revision_id']})
        write('review',{'revision_id':result['revision_id'],'decision':'approved','reason':'本地引导样例：检查素材与引用'},'reviewer')
    image=Path(image);asset=write('upload',{'name':'小鲸 · 正面参考图','filename':image.name,'data':base64.b64encode(image.read_bytes()).decode()});approve(asset)
    character=write('save',{'kind':'character','name':'小鲸','payload':{'persona':'日常搭子。嘴硬心软，贪吃爱摸鱼，会轻轻吐槽，不催聊、不惩罚错过。','voice':'Cherry','asset_revision':asset['revision_id']}});approve(character)
    content=write('save',{'kind':'content','name':'桌边打个招呼','payload':{'text':'又来看我？……行吧，给你留了个位置。','character_revision':character['revision_id']}});approve(content)
    event=write('save',{'kind':'event','name':'打个招呼','payload':{'content_revision':content['revision_id'],'trigger':'manual','target':'app_preview','cooldown_seconds':0,'ttl_seconds':3600}});approve(event)
    write('publish',{'name':'小鲸 · 基础回应示例','reason':'显式导入本地引导样例，未上线','revision_ids':[event['revision_id']],'channel':'preview','expected_release_id':None},'publisher')
    print('已创建小鲸引导样例：4个审核版本＋1个预览发布；操作有审计，未接入实体')
if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--data',default=str(Path(__file__).with_name('data')));parser.add_argument('--image',required=True)
    args=parser.parse_args();seed(args.data,args.image)
