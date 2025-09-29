const path = require('path');

module.exports = {
  apps: [
    {
      name: 'predictive-backend',
      script: 'cmd.exe',
      args: ['/c', path.join(__dirname, 'scripts', 'start-backend.bat')],
      cwd: __dirname,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '2G',
      min_uptime: '10s',
      max_restarts: 5,
      restart_delay: 4000,
      windowsHide: true,
      exec_mode: 'fork',
      env: {
        ASPNETCORE_ENVIRONMENT: 'Development',
        ASPNETCORE_URLS: 'http://localhost:5219'
      },
      env_production: {
        ASPNETCORE_ENVIRONMENT: 'Production',
        ASPNETCORE_URLS: 'http://localhost:5219'
      },
      log_file: './logs/backend-combined.log',
      out_file: './logs/backend-out.log',
      error_file: './logs/backend-error.log',
      time: true
    },
    {
      name: 'predictive-frontend',
      script: 'cmd.exe',
      args: ['/c', path.join(__dirname, 'scripts', 'start-frontend.bat')],
      cwd: __dirname,
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      min_uptime: '20s',
      max_restarts: 5,
      restart_delay: 5000,
      windowsHide: true,
      exec_mode: 'fork',
      env: {
        NODE_ENV: 'development'
      },
      env_production: {
        NODE_ENV: 'production'
      },
      log_file: './logs/frontend-combined.log',
      out_file: './logs/frontend-out.log',
      error_file: './logs/frontend-error.log',
      time: true
    }
  ]
};
