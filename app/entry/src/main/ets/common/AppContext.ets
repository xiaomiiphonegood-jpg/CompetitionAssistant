/**
 * 全局应用上下文存取：供 service 层获取 Context 用于本地存储
 */
import { common } from '@kit.AbilityKit';

let appContext: common.UIAbilityContext | null = null;

export function setAppContext(ctx: common.UIAbilityContext): void {
  appContext = ctx;
}

export function getAppContext(): common.UIAbilityContext | null {
  return appContext;
}
