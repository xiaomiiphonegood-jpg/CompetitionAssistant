/**
 * 大学生竞赛助手 - 云函数一键部署准备脚本
 *
 * 用途：在本地完成「语法校验 + 种子数据重新生成 + 部署清单核对」，
 *       把 AGC 控制台部署前的本地准备一步跑完，减少人工出错。
 *
 * 用法（在 cloudfunctions/ 目录下）：
 *   node deploy.js
 *
 * 说明：真正上传到 AGC Cloud Functions / Cloud DB 需在 AGC 控制台完成
 *      （本脚本不接触你的华为账号与 AGC 凭据），脚本会在最后打印精确步骤。
 */
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = __dirname;
const FILES = ['index.js', 'ai.js', 'seed.js'];

function run(cmd) {
  try {
    return execSync(cmd, { cwd: ROOT, encoding: 'utf8', stdio: ['pipe', 'pipe', 'pipe'] });
  } catch (e) {
    console.error('   ✗ 命令失败:', cmd);
    console.error(e.stdout || '');
    console.error(e.stderr || '');
    process.exit(1);
  }
}

function step(i, title) {
  console.log(`\n[${i}] ${title}`);
}

console.log('==============================================');
console.log('  大学生竞赛助手 · 云函数部署准备');
console.log('==============================================');

// 1. 语法校验
step(1, '校验云函数语法（node --check）');
let ok = true;
for (const f of FILES) {
  const full = path.join(ROOT, f);
  if (!fs.existsSync(full)) {
    console.error(`   ✗ 缺少文件 ${f}`);
    ok = false;
    continue;
  }
  try {
    execSync(`node --check "${f}"`, { cwd: ROOT, stdio: 'pipe' });
    console.log(`   ✓ ${f} 语法通过`);
  } catch (e) {
    console.error(`   ✗ ${f} 语法错误：\n${e.stderr || e.message}`);
    ok = false;
  }
}
if (!ok) {
  console.error('\n存在语法错误，已中止。请修复后重试。');
  process.exit(1);
}

// 2. 重新生成种子数据
step(2, '重新生成种子数据 seed-data.json');
run('node seed.js');
const seedPath = path.join(ROOT, 'seed-data.json');
let competitions = 0;
let stages = 0;
try {
  const seed = JSON.parse(fs.readFileSync(seedPath, 'utf8'));
  // seed-data.json 顶层字段为 competitions / competition_stages（数组），
  // 导入时分别映射到 Cloud DB 的 competition / competition_stage 集合。
  competitions = Array.isArray(seed.competitions) ? seed.competitions.length : 0;
  stages = Array.isArray(seed.competition_stages) ? seed.competition_stages.length : 0;
} catch (e) {
  console.error('   ✗ seed-data.json 解析失败:', e.message);
  process.exit(1);
}
console.log(`   ✓ 竞赛 ${competitions} 场，时间节点 ${stages} 个`);

// 3. 依赖提示
step(3, '依赖检查');
const pkg = JSON.parse(fs.readFileSync(path.join(ROOT, 'package.json'), 'utf8'));
console.log(`   · 依赖 @agconnect/cloud-server（AGC 运行时自动提供，本地无需 npm install）`);
console.log(`   · 上传文件：index.js + ai.js + package.json`);

// 4. 部署清单
step(4, 'AGC 控制台部署清单（需你手动完成）');
const checklist = [
  '1. 登录 AppGallery Connect，创建项目 + 应用（包名 com.campus.competitionassistant）',
  '2. 开通 Cloud DB、Cloud Functions',
  '3. Cloud DB 创建 7 个集合：competition / competition_stage / user_profile / favorite / study_plan / team_post / share_post',
  `4. 导入种子数据：把 seed-data.json 的 competition(${competitions}条)、competition_stage(${stages}条) 分别导入对应集合`,
  '5. Cloud Functions 创建函数，上传 index.js + ai.js + package.json',
  '6. 配置环境变量 DEEPSEEK_API_KEY = YOUR_DEEPSEEK_API_KEY',
  '7. 配置 HTTP 触发器，记录触发器地址（填入客户端 Constants.ets 的 CLOUD_FUNCTION_BASE）',
  '8. 客户端 Constants.ets：USE_MOCK 改 false、CLOUD_FUNCTION_BASE 填触发器地址',
];
for (const c of checklist) {
  console.log(`   ${c}`);
}

console.log('\n==============================================');
console.log('  本地准备完成 ✅ 按上面清单在 AGC 控制台完成部署即可');
console.log('==============================================');
