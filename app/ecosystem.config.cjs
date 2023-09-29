const os = require('os');

module.exports = {
  apps : [{
    name: "rpl-app",
    script: 'app.js',
    time: true,
    watch: false,
    instances: os.cpus().length,
    exec_mode: 'fork',
    wait_ready: true,
    env_production: {
      NODE_ENV: 'production'
    }
  }],
};
