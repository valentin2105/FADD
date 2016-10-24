// Dynamic config.js for Ghost modified from: https://gist.github.com/mewm/778644a11b0f28670fe4
//
// When using mysql, the MYSQL_* environment variables will be made available automatically
// by the Docker linking system

// Include any custom additions

console.log('Starting Ghost using dynamic config... :)')

var config,
    url = require('url'),
    path = require('path');

function getDatabase() {
  var db_config = {};
  // If we've linked in a mysql container, then this environment variable should be set
  if (process.env['MYSQL_NAME']) {
    db_config['client'] = 'mysql';
  } else {
    return {
      client: 'sqlite3',
      connection: {
        filename: path.join(process.env.GHOST_CONTENT, '/data/ghost.db')
      },
      debug: false
    };
  }
  var db_uri = /^tcp:\/\/([\d.]+):(\d+)$/.exec(process.env['DB_PORT']);
  if (db_uri) {
    db_config['connection'] = {
      host: db_uri[1],
      port: db_uri[2]
    };
  } else {
    db_config['connection'] = {
      host: process.env['DB_HOST'] || 'ghost_db_1',
      port: process.env['DB_PORT'] || '3306'
    };
  }
  if (process.env['MYSQL_ENV_MYSQL_USER']) db_config['connection']['user'] = process.env['MYSQL_ENV_MYSQL_USER'];
  if (process.env['MYSQL_ENV_MYSQL_PASSWORD']) db_config['connection']['password'] = process.env['MYSQL_ENV_MYSQL_PASSWORD'];
  if (process.env['MYSQL_ENV_MYSQL_DATABASE']) db_config['connection']['database'] = process.env['MYSQL_ENV_MYSQL_DATABASE'];
  return db_config;
}

function getMailConfig() {
  var mail_config = {}
  mail_config['options'] = {};
  mail_config['options']['auth'] = {};
  if (process.env['MAIL_TRANSPORT']){ mail_config['transport'] = process.env['MAIL_TRANSPORT'] };
  if (process.env['MAIL_SERVICE']) { mail_config['options']['service']   = process.env['MAIL_SERVICE'] }
  if (process.env['MAIL_USER']) { mail_config['options']['auth']['user'] = process.env['MAIL_USER'] }
  if (process.env['MAIL_PASS']) { mail_config['options']['auth']['pass'] = process.env['MAIL_PASS'] }
  return mail_config;
}
if (!process.env.URL) {
  console.log("Please set URL environment variable to your blog's URL");
  process.exit(1);
}

config = {
  production: {
    url: process.env.URL,
    database: getDatabase(),
    mail: getMailConfig(),
    server: {
      host: '0.0.0.0',
      port: '2368'
    },
    paths: {
      contentPath: path.join(process.env.GHOST_CONTENT, '/')
    }
  },
  development: {
    url: process.env.URL + ".dev",
    database: getDatabase(),
    mail: getMailConfig(),
    server: {
      host: '0.0.0.0',
      port: '2368'
    },
    paths: {
      contentPath: path.join(process.env.GHOST_CONTENT, '/')
    }
  },
};
module.exports = config;
