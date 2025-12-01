import axios from 'axios';

// 判断是否在打包环境中（通过检查是否有 /api 代理）
// 在开发环境中使用 /api 前缀，在生产环境(exe)中直接使用根路径
const getBaseURL = () => {
  // 如果在开发服务器中（有代理）使用 /api
  // 如果在生产环境（打包后）使用根路径
  if (import.meta.env.DEV) {
    return '/api';
  }
  // 生产环境直接使用根路径，因为后端和前端在同一个服务器上
  return '';
};

const api = axios.create({
  baseURL: getBaseURL(),
  timeout: 30000, // 默认30秒超时，各端点可单独覆盖
});

// 请求拦截器
api.interceptors.request.use(
  (config) => {
    const cardKey = localStorage.getItem('cardKey');
    if (cardKey) {
      config.params = {
        ...config.params,
        card_key: cardKey,
      };
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// 响应拦截器
api.interceptors.response.use(
  (response) => {
    return response;
  },
  (error) => {
    if (error.response?.status === 401) {
      localStorage.removeItem('cardKey');
      window.location.href = '/';
    }
    return Promise.reject(error);
  }
);

// Admin API
export const adminAPI = {
  generateKeys: (data, password) =>
    api.post('/admin/generate-keys', data, {
      params: { admin_password: password },
    }),
  listUsers: (password) =>
    api.get('/admin/users', {
      params: { admin_password: password },
    }),
  deleteUser: (userId, password) =>
    api.delete(`/admin/users/${userId}`, {
      params: { admin_password: password },
    }),
  stopSession: (sessionId, password) =>
    api.post(`/admin/sessions/${sessionId}/stop`, null, {
      params: { admin_password: password },
    }),
  toggleUserActive: (userId, password) =>
    api.put(`/admin/users/${userId}/toggle-active`, null, {
      params: { admin_password: password },
    }),
};

// Prompts API
export const promptsAPI = {
  getSystemPrompts: () => api.get('/prompts/system'),
  getUserPrompts: (stage = null) =>
    api.get('/prompts/', {
      params: stage ? { stage } : {},
    }),
  createPrompt: (data) => api.post('/prompts/', data),
  updatePrompt: (promptId, data) => api.put(`/prompts/${promptId}`, data),
  deletePrompt: (promptId) => api.delete(`/prompts/${promptId}`),
  setDefaultPrompt: (promptId) =>
    api.post(`/prompts/${promptId}/set-default`),
};

// Optimization API
export const optimizationAPI = {
  startOptimization: (data) => api.post('/optimization/start', data, {
    timeout: 60000, // 启动任务延长到60秒超时
  }),
  getQueueStatus: (sessionId = null) =>
    api.get('/optimization/status', {
      params: sessionId ? { session_id: sessionId } : {},
      timeout: 10000, // 10秒超时
    }),
  listSessions: () => api.get('/optimization/sessions', {
    timeout: 15000, // 15秒超时
  }),
  getSessionDetail: (sessionId) =>
    api.get(`/optimization/sessions/${sessionId}`, {
      timeout: 20000, // 20秒超时
    }),
  getSessionProgress: (sessionId) =>
    api.get(`/optimization/sessions/${sessionId}/progress`, {
      timeout: 10000, // 10秒超时
    }),
  getSessionChanges: (sessionId) =>
    api.get(`/optimization/sessions/${sessionId}/changes`, {
      timeout: 20000, // 20秒超时
    }),
  stopSession: (sessionId) =>
    api.post(`/optimization/sessions/${sessionId}/stop`, null, {
      timeout: 10000, // 10秒超时
    }),
  exportSession: (sessionId, confirmation) =>
    api.post(`/optimization/sessions/${sessionId}/export`, confirmation, {
      timeout: 30000, // 30秒超时
    }),
  deleteSession: (sessionId) =>
    api.delete(`/optimization/sessions/${sessionId}`, {
      timeout: 10000, // 10秒超时
    }),
  retryFailedSegments: (sessionId) =>
    api.post(`/optimization/sessions/${sessionId}/retry`, null, {
      timeout: 15000, // 15秒超时
    }),
  getStreamUrl: (sessionId) => {
    const cardKey = localStorage.getItem('cardKey');
    const baseUrl = api.defaults.baseURL || '';
    return `${baseUrl}/optimization/sessions/${sessionId}/stream?card_key=${cardKey}`;
  },
};

export default api;
