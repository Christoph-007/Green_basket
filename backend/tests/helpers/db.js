/**
 * Shared in-memory MongoDB for integration tests.
 * Uses mongodb-memory-server; set MONGOMS_SYSTEM_BINARY to use a local mongod.
 */
const mongoose = require('mongoose');
const { MongoMemoryServer } = require('mongodb-memory-server');

let mongoServer;

async function connect() {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());
}

async function clear() {
    const collections = mongoose.connection.collections;
    for (const key of Object.keys(collections)) {
        await collections[key].deleteMany({});
    }
}

async function disconnect() {
    await mongoose.connection.dropDatabase().catch(() => {});
    await mongoose.connection.close();
    if (mongoServer) await mongoServer.stop();
}

module.exports = { connect, clear, disconnect };
