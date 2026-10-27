/**
 * 系统级定时提醒服务：基于 reminderAgentManager 发布日历提醒
 * - 应用退出/被杀后仍由系统按时触发通知（进程无关）
 * - 权限：ohos.permission.PUBLISH_AGENT_REMINDER（需在 AGC 开放能力申请"代理提醒"）
 * - 每个应用最多 30 个有效提醒，本应用未来 90 天节点约 10 个，不会超限
 */
import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { ReminderItem } from '../model/Social';

export class ReminderService {
  /** 为单个竞赛节点发布一条日历提醒，返回 reminderId */
  static async publishReminder(item: ReminderItem): Promise<number> {
    const d = new Date(item.time);
    const request: reminderAgentManager.ReminderRequestCalendar = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_CALENDAR,
      dateTime: {
        year: d.getFullYear(),
        month: d.getMonth() + 1, // reminderAgentManager 的 month 为 1-12
        day: d.getDate(),
        hour: d.getHours(),
        minute: d.getMinutes()
      },
      title: `竞赛提醒：${item.competitionName}`,
      content: `${item.title} 将在 ${item.daysLeft} 天后到来，记得提前准备哦`
    };
    return reminderAgentManager.publishReminder(request);
  }

  /** 批量发布提醒（先清空旧提醒，避免重复累积），返回成功发布的条数 */
  static async publishAll(items: ReminderItem[]): Promise<number> {
    try {
      await reminderAgentManager.cancelAllReminders();
    } catch (e) {
      // 无旧提醒时忽略
    }
    let count = 0;
    for (const item of items) {
      try {
        await ReminderService.publishReminder(item);
        count++;
      } catch (e) {
        // 单条失败不影响其余
      }
    }
    return count;
  }
}
