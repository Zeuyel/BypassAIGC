import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  timeout: 300000, // 5分钟超时
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
  startOptimization: (data) => api.post('/optimization/start', data),
  getQueueStatus: (sessionId = null) =>
    api.get('/optimization/status', {
      params: sessionId ? { session_id: sessionId } : {},
    }),
  listSessions: () => api.get('/optimization/sessions'),
  getSessionDetail: (sessionId) =>
    api.get(`/optimization/sessions/${sessionId}`),
  getSessionProgress: (sessionId) =>
    api.get(`/optimization/sessions/${sessionId}/progress`),
  getSessionChanges: (sessionId) =>
    api.get(`/optimization/sessions/${sessionId}/changes`),
  exportSession: (sessionId, confirmation) =>
    api.post(`/optimization/sessions/${sessionId}/export`, confirmation),
  deleteSession: (sessionId) =>
    api.delete(`/optimization/sessions/${sessionId}`),
    retryFailedSegments: (sessionId) =>
      api.post(`/optimization/sessions/${sessionId}/retry`),
};

export default api;
