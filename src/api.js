// src/api.js
const isProduction = import.meta.env.MODE === 'production';
const API_BASE_URL = import.meta.env.VITE_API_URL || '';

// En desarrollo: usa ruta relativa (el proxy de Vite)
// En producción: usa URL completa del backend
export const API_URL = isProduction && API_BASE_URL
  ? `${API_BASE_URL}/api`  // Producción: http://api.plagavision.djrbweb.com:5002/api
  : '/api';                 // Desarrollo: /api (usa el proxy de Vite)

// Para debug (opcional)
console.log(`🔧 Modo: ${import.meta.env.MODE}`);
console.log(`🌐 API URL: ${API_URL}`);