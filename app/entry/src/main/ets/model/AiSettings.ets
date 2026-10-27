/**
 * AI 模型运行时配置模型
 * 用户在「设置 → 模型配置」中可修改，运行时读取，无需重新编译。
 */

export interface AiSettings {
  /** 服务商：deepseek | ollama | custom */
  provider: string;
  /** 接口基础地址，如 https://api.deepseek.com 或 http://服务器IP:11434 */
  baseUrl: string;
  /** 模型名称，如 deepseek-chat / qwen2.5:7b / llama3 */
  model: string;
  /** API Key（Ollama 本地模型可留空） */
  apiKey: string;
  /** true=使用本地模拟，false=真实调用大模型 */
  useMock: boolean;
}
