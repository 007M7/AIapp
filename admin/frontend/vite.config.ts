import {defineConfig} from 'vite';
import vue from '@vitejs/plugin-vue';
export default defineConfig({base:'/admin/',plugins:[vue()],server:{port:5175,strictPort:true,proxy:{'/api':{target:'http://127.0.0.1:8787',changeOrigin:true}}}});
