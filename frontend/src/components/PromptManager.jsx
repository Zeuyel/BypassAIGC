import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { toast } from 'react-hot-toast';
import { FileText, Plus, Edit, Trash2, Save, X, Eye, EyeOff } from 'lucide-react';

const PromptManager = ({ adminToken }) => {
  const [prompts, setPrompts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [editingPrompt, setEditingPrompt] = useState(null);
  
  const [formData, setFormData] = useState({
    name: '',
    type: 'polish',
    content: '',
    is_system_default: false
  });

  useEffect(() => {
    fetchPrompts();
  }, []);

  const fetchPrompts = async () => {
    setLoading(true);
    try {
      const response = await axios.get('/api/admin/prompts', {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      setPrompts(response.data);
    } catch (error) {
      toast.error('获取提示词列表失败');
    } finally {
      setLoading(false);
    }
  };

  const handleCreate = () => {
    setEditingPrompt(null);
    setFormData({
      name: '',
      type: 'polish',
      content: '',
      is_system_default: false
    });
    setShowModal(true);
  };

  const handleEdit = (prompt) => {
    setEditingPrompt(prompt);
    setFormData({
      name: prompt.name,
      type: prompt.type,
      content: prompt.content,
      is_system_default: prompt.is_system_default
    });
    setShowModal(true);
  };

  const handleSave = async () => {
    if (!formData.name || !formData.content) {
      toast.error('请填写完整信息');
      return;
    }

    try {
      if (editingPrompt) {
        // 更新
        await axios.put(`/api/admin/prompts/${editingPrompt.id}`, {
          name: formData.name,
          content: formData.content
        }, {
          headers: { Authorization: `Bearer ${adminToken}` }
        });
        toast.success('提示词更新成功');
      } else {
        // 创建
        await axios.post('/api/admin/prompts', formData, {
          headers: { Authorization: `Bearer ${adminToken}` }
        });
        toast.success('提示词创建成功');
      }
      
      setShowModal(false);
      fetchPrompts();
    } catch (error) {
      toast.error(error.response?.data?.detail || '操作失败');
    }
  };

  const handleToggleActive = async (promptId, currentStatus) => {
    try {
      await axios.put(`/api/admin/prompts/${promptId}`, {
        is_active: !currentStatus
      }, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      toast.success(currentStatus ? '已禁用' : '已启用');
      fetchPrompts();
    } catch (error) {
      toast.error('操作失败');
    }
  };

  const handleDelete = async (promptId, isSystemDefault) => {
    if (isSystemDefault) {
      toast.error('系统默认提示词不能删除');
      return;
    }

    if (!window.confirm('确定要删除这个提示词吗？')) {
      return;
    }

    try {
      await axios.delete(`/api/admin/prompts/${promptId}`, {
        headers: { Authorization: `Bearer ${adminToken}` }
      });
      toast.success('提示词已删除');
      fetchPrompts();
    } catch (error) {
      toast.error(error.response?.data?.detail || '删除失败');
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-3">
          <FileText className="w-6 h-6 text-blue-600" />
          <h3 className="text-xl font-semibold text-gray-800">提示词管理</h3>
        </div>
        <button
          onClick={handleCreate}
          className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
        >
          <Plus className="w-5 h-5" />
          新建提示词
        </button>
      </div>

      {loading ? (
        <div className="flex items-center justify-center py-12">
          <div className="w-8 h-8 border-4 border-blue-600 border-t-transparent rounded-full animate-spin" />
        </div>
      ) : prompts.length === 0 ? (
        <div className="text-center py-12 text-gray-500">
          暂无提示词
        </div>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {prompts.map((prompt) => (
            <div key={prompt.id} className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
              <div className="flex items-start justify-between mb-4">
                <div>
                  <div className="flex items-center gap-2">
                    <h4 className="text-lg font-semibold text-gray-800">{prompt.name}</h4>
                    {prompt.is_system_default && (
                      <span className="px-2 py-1 bg-blue-100 text-blue-800 text-xs font-medium rounded">
                        系统默认
                      </span>
                    )}
                  </div>
                  <div className="flex items-center gap-2 mt-1">
                    <span className={`px-2 py-1 text-xs font-medium rounded ${
                      prompt.type === 'polish' 
                        ? 'bg-green-100 text-green-800'
                        : 'bg-purple-100 text-purple-800'
                    }`}>
                      {prompt.type === 'polish' ? '润色' : '增强'}
                    </span>
                    <span className={`px-2 py-1 text-xs font-medium rounded ${
                      prompt.is_active
                        ? 'bg-green-100 text-green-800'
                        : 'bg-red-100 text-red-800'
                    }`}>
                      {prompt.is_active ? '启用' : '禁用'}
                    </span>
                  </div>
                </div>
              </div>

              <div className="bg-gray-50 rounded-lg p-4 mb-4">
                <p className="text-sm text-gray-700 line-clamp-3">
                  {prompt.content}
                </p>
              </div>

              <div className="flex items-center gap-2 text-xs text-gray-500 mb-4">
                <span>创建: {new Date(prompt.created_at).toLocaleString('zh-CN')}</span>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => handleEdit(prompt)}
                  className="flex-1 flex items-center justify-center gap-1 px-3 py-2 bg-blue-100 hover:bg-blue-200 text-blue-800 rounded transition-colors"
                >
                  <Edit className="w-4 h-4" />
                  编辑
                </button>
                <button
                  onClick={() => handleToggleActive(prompt.id, prompt.is_active)}
                  className={`flex-1 flex items-center justify-center gap-1 px-3 py-2 rounded transition-colors ${
                    prompt.is_active
                      ? 'bg-yellow-100 hover:bg-yellow-200 text-yellow-800'
                      : 'bg-green-100 hover:bg-green-200 text-green-800'
                  }`}
                >
                  {prompt.is_active ? <EyeOff className="w-4 h-4" /> : <Eye className="w-4 h-4" />}
                  {prompt.is_active ? '禁用' : '启用'}
                </button>
                {!prompt.is_system_default && (
                  <button
                    onClick={() => handleDelete(prompt.id, prompt.is_system_default)}
                    className="px-3 py-2 bg-red-100 hover:bg-red-200 text-red-800 rounded transition-colors"
                  >
                    <Trash2 className="w-4 h-4" />
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}

      {/* 编辑/创建模态框 */}
      {showModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-2xl w-full p-6 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between mb-6">
              <h3 className="text-xl font-bold text-gray-800">
                {editingPrompt ? '编辑提示词' : '新建提示词'}
              </h3>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-400 hover:text-gray-600"
              >
                <X className="w-6 h-6" />
              </button>
            </div>

            <div className="space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  名称
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) => setFormData({...formData, name: e.target.value})}
                  placeholder="提示词名称"
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  类型
                </label>
                <select
                  value={formData.type}
                  onChange={(e) => setFormData({...formData, type: e.target.value})}
                  disabled={editingPrompt}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent disabled:bg-gray-100"
                >
                  <option value="polish">润色</option>
                  <option value="enhance">增强</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  内容
                </label>
                <textarea
                  value={formData.content}
                  onChange={(e) => setFormData({...formData, content: e.target.value})}
                  placeholder="输入提示词内容..."
                  rows={12}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent font-mono text-sm"
                />
              </div>

              {!editingPrompt && (
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    id="is_system_default"
                    checked={formData.is_system_default}
                    onChange={(e) => setFormData({...formData, is_system_default: e.target.checked})}
                    className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                  />
                  <label htmlFor="is_system_default" className="text-sm text-gray-700">
                    设为系统默认提示词
                  </label>
                </div>
              )}
            </div>

            <div className="flex gap-3 mt-6">
              <button
                onClick={() => setShowModal(false)}
                className="flex-1 px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-800 rounded-lg transition-colors"
              >
                取消
              </button>
              <button
                onClick={handleSave}
                className="flex-1 flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors"
              >
                <Save className="w-5 h-5" />
                保存
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default PromptManager;
