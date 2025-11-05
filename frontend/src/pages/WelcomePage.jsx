import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import toast from 'react-hot-toast';
import { Shield, ArrowRight } from 'lucide-react';
import axios from 'axios';

const WelcomePage = () => {
  const [cardKey, setCardKey] = useState('');
  const [showWarning, setShowWarning] = useState(false);
  const [loading, setLoading] = useState(false);
  const navigate = useNavigate();

  const handleContinue = async () => {
    if (!cardKey.trim()) {
      toast.error('请输入卡密');
      return;
    }
    
    // 验证卡密
    setLoading(true);
    try {
      const response = await axios.post('/api/admin/verify-card-key', {
        card_key: cardKey
      });
      
      if (response.data.valid) {
        setShowWarning(true);
      }
    } catch (error) {
      toast.error(error.response?.data?.detail || '卡密验证失败，请检查卡密是否正确');
    } finally {
      setLoading(false);
    }
  };

  const handleAccept = () => {
    localStorage.setItem('cardKey', cardKey);
    navigate('/workspace');
  };

  return (
    <div className="min-h-screen bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 flex items-center justify-center p-4">
      <div className="max-w-md w-full">
        {!showWarning ? (
          <div className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-2xl p-10 space-y-8">
            {/* Logo/标题区域 */}
            <div className="text-center space-y-3">
              <div className="inline-flex items-center justify-center w-20 h-20 bg-gradient-to-br from-blue-500 to-purple-600 rounded-2xl shadow-lg mb-4">
                <svg className="w-12 h-12 text-white" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                </svg>
              </div>
              <h1 className="text-3xl font-bold bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                AI 学术写作助手
              </h1>
              <p className="text-gray-500 text-sm">
                专业论文润色 · 智能语言优化
              </p>
            </div>

            {/* 输入区域 */}
            <div className="space-y-4">
              <div className="space-y-2">
                <label className="block text-sm font-semibold text-gray-700">
                  访问卡密
                </label>
                <input
                  type="text"
                  value={cardKey}
                  onChange={(e) => setCardKey(e.target.value)}
                  onKeyPress={(e) => e.key === 'Enter' && !loading && cardKey.trim() && handleContinue()}
                  placeholder="请输入卡密"
                  className="w-full px-4 py-3.5 bg-gray-50 border border-gray-200 rounded-xl focus:ring-2 focus:ring-purple-500 focus:border-transparent transition-all text-gray-800 placeholder-gray-400"
                />
              </div>

              <button
                onClick={handleContinue}
                disabled={loading || !cardKey.trim()}
                className="w-full bg-gradient-to-r from-blue-600 to-purple-600 hover:from-blue-700 hover:to-purple-700 disabled:from-gray-400 disabled:to-gray-400 disabled:cursor-not-allowed text-white font-semibold py-3.5 px-6 rounded-xl transition-all shadow-lg hover:shadow-xl transform hover:scale-[1.02] disabled:transform-none flex items-center justify-center gap-2"
              >
                {loading ? (
                  <>
                    <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    验证中...
                  </>
                ) : (
                  <>
                    开始使用
                    <ArrowRight className="w-5 h-5" />
                  </>
                )}
              </button>
            </div>

            {/* 底部提示 */}
            <div className="text-center pt-4 border-t border-gray-100">
              <p className="text-xs text-gray-400">
                使用本系统即表示您同意遵守学术诚信规范
              </p>
            </div>
          </div>
        ) : (
          <div className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-2xl p-10 space-y-6">
            {/* 图标和标题 */}
            <div className="text-center">
              <div className="inline-flex items-center justify-center w-16 h-16 bg-gradient-to-br from-yellow-400 to-orange-500 rounded-2xl shadow-lg mb-4">
                <Shield className="w-10 h-10 text-white" />
              </div>
              <h2 className="text-2xl font-bold text-gray-800 mb-2">
                学术诚信承诺
              </h2>
              <p className="text-sm text-gray-500">请仔细阅读以下条款</p>
            </div>

            {/* 条款内容 */}
            <div className="bg-gradient-to-br from-orange-50 to-yellow-50 rounded-2xl p-6 space-y-4 border border-orange-100">
              <div className="space-y-3 text-gray-700 text-sm leading-relaxed">
                <div className="flex gap-3">
                  <span className="flex-shrink-0 w-6 h-6 bg-orange-500 text-white rounded-full flex items-center justify-center text-xs font-bold">1</span>
                  <p>本系统仅作为语言润色工具，不应替代原创研究与学术思考</p>
                </div>
                <div className="flex gap-3">
                  <span className="flex-shrink-0 w-6 h-6 bg-orange-500 text-white rounded-full flex items-center justify-center text-xs font-bold">2</span>
                  <p>论文的核心观点、研究方法、数据分析必须为您的原创工作</p>
                </div>
                <div className="flex gap-3">
                  <span className="flex-shrink-0 w-6 h-6 bg-orange-500 text-white rounded-full flex items-center justify-center text-xs font-bold">3</span>
                  <p>您需审核所有优化内容，并对最终提交的论文负全部责任</p>
                </div>
                <div className="flex gap-3">
                  <span className="flex-shrink-0 w-6 h-6 bg-orange-500 text-white rounded-full flex items-center justify-center text-xs font-bold">4</span>
                  <p>根据机构规定，您可能需要声明使用了 AI 辅助工具</p>
                </div>
              </div>
            </div>

            {/* 警告提示 */}
            <div className="bg-red-50 border border-red-200 rounded-xl p-4">
              <div className="flex gap-3">
                <span className="text-red-500 text-xl">⚠️</span>
                <p className="text-red-700 text-sm font-medium">
                  学术不端行为可能导致严重后果，包括论文撤稿、学位取消等
                </p>
              </div>
            </div>

            {/* 按钮组 */}
            <div className="grid grid-cols-2 gap-3 pt-2">
              <button
                onClick={() => setShowWarning(false)}
                className="bg-gray-100 hover:bg-gray-200 text-gray-700 font-semibold py-3.5 px-6 rounded-xl transition-all"
              >
                返回
              </button>
              <button
                onClick={handleAccept}
                className="bg-gradient-to-r from-green-500 to-emerald-600 hover:from-green-600 hover:to-emerald-700 text-white font-semibold py-3.5 px-6 rounded-xl transition-all shadow-lg hover:shadow-xl transform hover:scale-[1.02]"
              >
                同意并继续
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};

export default WelcomePage;
