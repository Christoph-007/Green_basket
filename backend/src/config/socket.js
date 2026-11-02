const socketIO = require('socket.io');
const jwt = require('jsonwebtoken');

let io;

const initializeSocket = (server) => {
    io = socketIO(server, {
        cors: {
            origin: require('./cors').corsOrigin,
            methods: ['GET', 'POST'],
            credentials: true
        }
    });

    // Socket authentication middleware
    io.use((socket, next) => {
        const token = socket.handshake.auth.token;

        if (!token) {
            return next(new Error('Authentication error'));
        }

        try {
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            if (decoded.tokenType === 'refresh') return next(new Error('Authentication error'));
            socket.userId = decoded.id;
            socket.userType = decoded.userType; // 'user', 'merchant', or 'admin'
            next();
        } catch (error) {
            next(new Error('Authentication error'));
        }
    });

    io.on('connection', (socket) => {
        console.log(`🔌 User connected: ${socket.userId} (${socket.userType})`);

        // Join user to their personal room
        socket.join(`${socket.userType}_${socket.userId}`);

        // Handle disconnection
        socket.on('disconnect', () => {
            console.log(`🔌 User disconnected: ${socket.userId}`);
        });
    });

    return io;
};

const getIO = () => {
    if (!io) {
        throw new Error('Socket.io not initialized');
    }
    return io;
};

module.exports = { initializeSocket, getIO };
