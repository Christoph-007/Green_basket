const Redis = require('ioredis');

const redisClient = new Redis(process.env.REDIS_URL || 'redis://localhost:6379', {
    // Retry strategy: retry every 2 seconds
    retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
    },
    // Don't crash if Redis is unavailable, just log error
    lazyConnect: true // do not connect until the first command is sent
});

redisClient.on('error', (err) => {
    // Suppress connection refused errors in development to avoid console spam if Redis isn't running
    if (err.code === 'ECONNREFUSED') {
        console.warn('⚠️ Redis Connection Error: Connection Refused (Is Redis server running?)');
    } else {
        console.error('❌ Redis Client Error:', err.message);
    }
});

redisClient.on('connect', () => {
    console.log('✅ Redis Connected Successfully');
});

module.exports = redisClient;
