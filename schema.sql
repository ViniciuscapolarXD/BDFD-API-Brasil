CREATE TABLE IF NOT EXISTS bots (
  id TEXT PRIMARY KEY,
  label TEXT,
  discord_user_id TEXT NOT NULL UNIQUE,
  discord_username TEXT,
  token_cipher TEXT NOT NULL,
  token_iv TEXT NOT NULL,
  api_key_hash TEXT NOT NULL UNIQUE,
  enabled INTEGER NOT NULL DEFAULT 1,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS variables (
  bot_id TEXT NOT NULL,
  scope TEXT NOT NULL,
  guild_id TEXT NOT NULL DEFAULT '',
  user_id TEXT NOT NULL DEFAULT '',
  name TEXT NOT NULL,
  value_json TEXT NOT NULL,
  expires_at INTEGER,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (bot_id, scope, guild_id, user_id, name)
);
CREATE INDEX IF NOT EXISTS idx_variables_name ON variables(bot_id, scope, name);

CREATE TABLE IF NOT EXISTS leaderboard (
  bot_id TEXT NOT NULL,
  board TEXT NOT NULL,
  user_id TEXT NOT NULL,
  score REAL NOT NULL DEFAULT 0,
  metadata_json TEXT,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (bot_id, board, user_id)
);
CREATE INDEX IF NOT EXISTS idx_leaderboard_score ON leaderboard(bot_id, board, score, user_id);

CREATE TABLE IF NOT EXISTS cooldowns (
  bot_id TEXT NOT NULL,
  bucket TEXT NOT NULL,
  subject TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (bot_id, bucket, subject)
);
CREATE INDEX IF NOT EXISTS idx_cooldowns_bucket ON cooldowns(bot_id, bucket, expires_at);

CREATE TABLE IF NOT EXISTS locks (
  bot_id TEXT NOT NULL,
  bucket TEXT NOT NULL,
  subject TEXT NOT NULL,
  lease_id TEXT NOT NULL,
  expires_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (bot_id, bucket, subject)
);
