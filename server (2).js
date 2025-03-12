require('dotenv').config();
const express = require('express');
const { createServer } = require('http');
const { Server } = require('socket.io');
const mysql = require('mysql2/promise');

const app = express();
const httpServer = createServer(app);

const JOKER_TYPES = {
    BLOCK: 'block',    // Blokaj Jokeri
    HOOK: 'hook',      // Kanca Jokeri
    BET: 'bet'         // Bahis Jokeri
};

// Yeni oyun aşamaları
const GAME_PHASE = {
    PREPARATION: 'preparation',  // Hazırlık aşaması (her iki oyuncu da hazır olmalı)
    CARD_SELECT: 'cardSelect',   // Taş kağıt makas seçimi
    REVEALING: 'revealing',      // Kartların gösterilmesi
    ROUND_RESULT: 'roundResult', // Round sonucu
    JOKER_SELECT: 'jokerSelect', // Joker seçimi
    JOKER_REVEAL: 'jokerReveal', // Joker gösterimi
    ROUND_END: 'roundEnd'        // Round sonu ve sonraki rounda geçiş
};

// Socket.IO server yapılandırması
const io = new Server(httpServer, {
    cors: {
        origin: "*", // Geliştirme aşamasında tüm originlere izin ver
        methods: ["GET", "POST"]
    },
    pingTimeout: parseInt(process.env.SOCKET_PING_TIMEOUT),
    pingInterval: parseInt(process.env.SOCKET_PING_INTERVAL)
});

// Veritabanı havuzu oluştur
const pool = mysql.createPool({
    host: process.env.DB_HOST,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    database: process.env.DB_NAME,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

// Oyun odalarını ve aktif oyuncuları tutacak Map'ler
const activePlayers = new Map(); // socketId -> {userId, league, gamePreferences}
const waitingPlayers = new Map(); // league -> [{socketId, userId, betAmount}]
const activeGames = new Map(); // gameId -> {gameState, players, timer}

// Socket bağlantılarını yönet
io.on('connection', async (socket) => {
    console.log('New connection:', socket.id);

    // Oyuncu kimlik doğrulama
    socket.on('auth', async (data) => {
        try {
            const { userId, deviceId } = data;
            // Veritabanından kullanıcı kontrolü
            const [rows] = await pool.execute(
                'SELECT user_id, current_league, current_gold FROM users WHERE user_id = ?',
                [userId]
            );

            if (rows.length > 0) {
                // Kullanıcı bilgilerini sakla
                activePlayers.set(socket.id, {
                    userId: rows[0].user_id,
                    league: rows[0].current_league,
                    gold: rows[0].current_gold,
                    deviceId
                });
                socket.emit('auth:success');
            } else {
                socket.emit('auth:failed', { message: 'User not found' });
            }
        } catch (error) {
            console.error('Auth error:', error);
            socket.emit('auth:failed', { message: 'Authentication error' });
        }
    });

    // Oyun arama
    socket.on('matchmaking:find', async (data) => {
        const { betAmount, targetWins } = data;
        const player = activePlayers.get(socket.id);
    
        if (!player) {
            socket.emit('error', { message: 'Not authenticated' });
            return;
        }
    
        if (player.gold < betAmount) {
            socket.emit('error', { message: 'Insufficient gold' });
            return;
        }
    
        if (![3, 5].includes(targetWins)) {
            socket.emit('error', { message: 'Invalid target wins count' });
            return;
        }
    
        await matchPlayers(socket, player.league, betAmount, targetWins);
    });

    // Hazırım mesajı
    socket.on('game:ready', async (data) => {
        const { gameId } = data;
        const game = activeGames.get(gameId);
        const player = activePlayers.get(socket.id);
        
        if (!game || !player) return;
        
        const isPlayer1 = player.userId === game.players.player1.id;
        if (isPlayer1) {
            game.players.player1.isReady = true;
        } else {
            game.players.player2.isReady = true;
        }
        
        // Hazırlık durumunu bildirme
        io.to(`game_${gameId}`).emit('game:playerReady', {
            playerId: player.userId,
            player: isPlayer1 ? 'player1' : 'player2'
        });
        
        // İki oyuncu da hazırsa oyunu başlat ve allReady olayını gönder
        if (game.players.player1.isReady && game.players.player2.isReady) {
            // BURAYA EKLEDİK: Tüm oyuncuların hazır olduğunu bildir
            io.to(`game_${gameId}`).emit('game:allReady', {
                gameId: gameId
            });
            
            clearTimeout(game.preparationTimer);
            startGame(gameId);
        }
    });

    // Oyun hamlesi
    socket.on('game:move', async (data) => {
        const { gameId, move } = data;
        const game = activeGames.get(gameId);
        const player = activePlayers.get(socket.id);
    
        if (!game || !player || game.currentPhase !== GAME_PHASE.CARD_SELECT) return;
    
        const isPlayer1 = player.userId === game.players.player1.id;
        const playerObj = isPlayer1 ? game.players.player1 : game.players.player2;
    
        // Hamleyi kaydet
        playerObj.currentMove = move;
        
        // İki oyuncu da hamlesini yaptıysa ve süre bitmemişse sonuç fazına geç
        if (game.players.player1.currentMove && game.players.player2.currentMove) {
            clearTimeout(game.phaseTimer);
            startRevealingPhase(gameId);
        }
    });

    // Joker kullanımı
    socket.on('game:joker', async (data) => {
        const { gameId, jokerType } = data;
        const game = activeGames.get(gameId);
        const player = activePlayers.get(socket.id);
    
        if (!game || !player || game.currentPhase !== GAME_PHASE.JOKER_SELECT) return;
    
        const isPlayer1 = player.userId === game.players.player1.id;
        const playerObj = isPlayer1 ? game.players.player1 : game.players.player2;
    
        // Joker kullanım hakkı kontrolü
        if (playerObj.jokers[jokerType] > 0) {
            playerObj.currentJoker = jokerType;
            playerObj.jokers[jokerType]--;
            
            // İki oyuncu da joker seçimini yaptıysa ve süre bitmemişse joker gösterim fazına geç
            if (game.players.player1.currentJoker !== null && game.players.player2.currentJoker !== null) {
                clearTimeout(game.phaseTimer);
                startJokerRevealPhase(gameId);
            }
        }
    });

    socket.on('game:surrender', async (data) => {
        const { gameId } = data;
        const game = activeGames.get(gameId);
        const player = activePlayers.get(socket.id);
        
        if (!game || !player) return;
        
        // Oyuncunun ID'sini kontrol et
        const isPlayer1 = player.userId === game.players.player1.id;
        const loserUserId = player.userId;
        const winnerUserId = isPlayer1 ? game.players.player2.id : game.players.player1.id;
        
        console.log(`Player ${loserUserId} surrendered in game ${gameId}`);
        
        try {
            // Oyunu güncelle
            await pool.execute(
                'UPDATE games SET status = ?, winner = ?, ended_at = NOW() WHERE game_id = ?',
                ['SURRENDERED', winnerUserId, gameId]
            );
            // Kazanan oyuncuya ödül ver
            await pool.execute(
                'UPDATE users SET current_gold = current_gold + ? WHERE user_id = ?',
                [game.betAmount * 1.5, winnerUserId]
            );
        } catch (error) {
            console.error('Game surrender handling error:', error);
        }
        // Diğer oyuncuya bildir
        io.to(`game_${gameId}`).emit('game:surrendered', {
            surrenderedPlayer: loserUserId,
            winner: winnerUserId
        });
        // Oyunu kapat
        activeGames.delete(gameId);
    });
    
    // Eşleşme iptali
    socket.on('matchmaking:cancel', (data) => {
        const player = activePlayers.get(socket.id);
        
        if (!player) return;
        
        // Kullanıcıyı bekleme listesinden çıkar
        for (const [league, players] of waitingPlayers.entries()) {
            waitingPlayers.set(
                league, 
                players.filter(p => p.socketId !== socket.id)
            );
        }
        
        console.log(`Player ${player.userId} cancelled matchmaking`);
        
        // Eğer aktif bir oyun varsa onu da temizle
        const { gameId } = data;
        if (gameId) {
            const game = activeGames.get(gameId);
            if (game) {
                // Diğer oyuncuya bildir
                const isPlayer1 = player.userId === game.players.player1.id;
                const otherPlayerId = isPlayer1 ? game.players.player2.id : game.players.player1.id;
                const otherPlayerSocket = findSocketByUserId(otherPlayerId);
                
                if (otherPlayerSocket) {
                    otherPlayerSocket.emit('game:cancelled', {
                        message: 'Rakip eşleşmeyi iptal etti'
                    });
                }
                
                // İptal edene bahis ücretini geri ver
                try {
                    pool.execute(
                        'UPDATE users SET current_gold = current_gold + ? WHERE user_id = ?',
                        [game.betAmount, player.userId]
                    );
                } catch (error) {
                    console.error('Error refunding bet amount:', error);
                }
                
                // Oyunu temizle
                activeGames.delete(gameId);
            }
        }
    });


    // Bağlantı kopması
    socket.on('disconnect', () => {
        handleDisconnect(socket);
    });
});

// Oyuncu eşleştirme fonksiyonu
async function matchPlayers(socket, league, betAmount, rounds) {
    console.log(`Matching player - Socket: ${socket.id}, League: ${league}, Bet: ${betAmount}, Rounds: ${rounds}`);

    const waitingPlayersInLeague = waitingPlayers.get(league) || [];
    const currentPlayer = activePlayers.get(socket.id);

    console.log('Current waiting players:', waitingPlayersInLeague);
    
    // Aynı round sayısı ve bahis miktarına sahip oyuncuları eşleştir
    const opponent = waitingPlayersInLeague.find(p => 
        p.betAmount === betAmount && 
        p.rounds === rounds &&
        p.socketId !== socket.id &&
        p.userId !== currentPlayer.userId
    );

    if (opponent) {
        // Eşleşme bulundu, bekleme listesinden çıkar
        cleanupWaitingPlayer(opponent.socketId, league);

        const gameId = generateGameId();
        const player1Socket = io.sockets.sockets.get(opponent.socketId);
        const player2Socket = socket;

        if (!player1Socket) {
            // Rakip bağlantısı kopmuş
            socket.emit('error', { message: 'Opponent disconnected' });
            return;
        }

        // Oyun odası oluştur
        const gameRoom = `game_${gameId}`;
        player1Socket.join(gameRoom);
        player2Socket.join(gameRoom);

        // Oyun durumunu oluştur
        const gameState = createInitialGameState(gameId, opponent.userId, currentPlayer.userId, betAmount, rounds);
        activeGames.set(gameId, gameState);

        // Oyunculara eşleşme bilgisini gönder (takım renklerini de ekleyerek)
        io.to(player1Socket.id).emit('game:matched', {
            gameId,
            opponent: {
                id: currentPlayer.userId
            },
            betAmount,
            targetWins: rounds,
            player1Id: opponent.userId,
            player2Id: currentPlayer.userId,
            isGreenTeam: 1  // İlk oyuncu yeşil takım
        });

        io.to(player2Socket.id).emit('game:matched', {
            gameId,
            opponent: {
                id: opponent.userId
            },
            betAmount,
            targetWins: rounds,
            player1Id: opponent.userId,
            player2Id: currentPlayer.userId,
            isGreenTeam: 0  // İkinci oyuncu kırmızı takım
        });

        // Hazırlık aşamasını başlat
        startPreparationPhase(gameId);

        try {
            await pool.execute(
                'INSERT INTO games (game_id, player1_id, player2_id, bet_amount, status, started_at, rounds) VALUES (?, ?, ?, ?, ?, NOW(), ?)',
                [gameId, opponent.userId, currentPlayer.userId, betAmount, 'PLAYING', rounds]
            );
        } catch (error) {
            console.error('Game creation error:', error);
        }
    } else {
        // Eşleşme bulunamadı, bekleme listesine ekle
        waitingPlayers.set(league, [
            ...waitingPlayersInLeague,
            {
                socketId: socket.id,
                userId: currentPlayer.userId,
                betAmount,
                rounds,
                joinedAt: Date.now()
            }
        ]);

        console.log(`Player ${currentPlayer.userId} added to waiting list`);

        socket.emit('matchmaking:waiting');
    }
}

// Hazırlık aşamasını başlat
function startPreparationPhase(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;
    
    game.currentPhase = GAME_PHASE.PREPARATION;
    
    // Hazırlık aşaması bilgisini gönder
    io.to(`game_${gameId}`).emit('game:preparationPhase', {
        timeLimit: 10,
        message: 'Hazır olduğunuzda "Hazırım" butonuna basın.'
    });
    
    // 10 saniye içinde iki oyuncu da hazır olmazsa kontrol et
    game.preparationTimer = setTimeout(() => {
        checkPreparationStatus(gameId);
    }, 10000);
}

// Hazırlık durumu kontrolü
function checkPreparationStatus(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;
    
    if (game.players.player1.isReady && game.players.player2.isReady) {
        io.to(`game_${gameId}`).emit('game:allReady', {
            gameId: gameId
        });
        
        clearTimeout(game.preparationTimer);
        
        // 3 saniye bekle, sonra oyunu başlat (Değişiklik burada: 2 -> 3)
        setTimeout(() => {
            startGame(gameId);
        }, 3000);
    } else if (game.players.player1.isReady) {
        // Sadece oyuncu 1 hazır
        handleReadyPlayer(game.players.player1.id, game.players.player2.id);
        activeGames.delete(gameId);
    } else if (game.players.player2.isReady) {
        // Sadece oyuncu 2 hazır
        handleReadyPlayer(game.players.player2.id, game.players.player1.id);
        activeGames.delete(gameId);
    } else {
        // İki oyuncu da hazır değil, ikisini de eşleşmeden çıkar
        handleBothNotReady(game.players.player1.id, game.players.player2.id);
        activeGames.delete(gameId);
    }
}

// Hazır oyuncuyu yeniden eşleşme sürecine alır
function handleReadyPlayer(readyPlayerId, notReadyPlayerId) {
    // Hazır olmayan oyuncuyu bilgilendir
    const notReadyPlayerSocket = findSocketByUserId(notReadyPlayerId);
    if (notReadyPlayerSocket) {
        notReadyPlayerSocket.emit('game:preparationFailed', {
            message: 'Hazır olmadığınız için eşleşme iptal edildi.'
        });
    }
    
    // Hazır olan oyuncuyu yeniden eşleşme sürecine al
    const readyPlayerSocket = findSocketByUserId(readyPlayerId);
    if (readyPlayerSocket) {
        const player = activePlayers.get(readyPlayerSocket.id);
        if (player) {
            readyPlayerSocket.emit('game:rematching', {
                message: 'Rakibiniz hazır olmadı. Yeni eşleşme aranıyor...'
            });
            
            // Yeniden eşleşme için oyuncunun bilgilerini al
            const socketObj = io.sockets.sockets.get(readyPlayerSocket.id);
            if (socketObj) {
                socketObj.emit('matchmaking:waiting');
            }
        }
    }
}

// İki oyuncunun da hazır olmadığı durumu işler
function handleBothNotReady(player1Id, player2Id) {
    const player1Socket = findSocketByUserId(player1Id);
    const player2Socket = findSocketByUserId(player2Id);
    
    if (player1Socket) {
        player1Socket.emit('game:preparationFailed', {
            message: 'Hazır olmadığınız için eşleşme iptal edildi.'
        });
    }
    
    if (player2Socket) {
        player2Socket.emit('game:preparationFailed', {
            message: 'Hazır olmadığınız için eşleşme iptal edildi.'
        });
    }
}

// UserId'ye göre socket bul
function findSocketByUserId(userId) {
    for (const [socketId, player] of activePlayers.entries()) {
        if (player.userId === userId) {
            return io.sockets.sockets.get(socketId);
        }
    }
    return null;
}

// Oyunu başlat
function startGame(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;
    
    // Oyunculara oyunun başladığı bilgisini gönder
    io.to(`game_${gameId}`).emit('game:start', {
        player1Id: game.players.player1.id,
        player2Id: game.players.player2.id,
        targetWins: game.targetWins,
        betAmount: game.betAmount
    });
    
    // İlk roundu başlat
    startNewRound(gameId);
}

// Yeni round başlat
function startNewRound(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    // Round sayacını artır
    game.currentRound++;
    
    // Hamleleri sıfırla
    game.players.player1.currentMove = null;
    game.players.player2.currentMove = null;
    game.players.player1.currentJoker = null;
    game.players.player2.currentJoker = null;

    // Önceki rounddan kalan blokaj ayarlarını uygula
    game.players.player1.blockedMoves = [...game.players.player1.nextRoundBlockedMoves];
    game.players.player2.blockedMoves = [...game.players.player2.nextRoundBlockedMoves];
    
    // Güncel blokaj durumlarını loglama
    console.log("Tur başlangıcı - Bloke durumları:", {
        player1BlockedMoves: game.players.player1.blockedMoves,
        player2BlockedMoves: game.players.player2.blockedMoves
    });
    
    // Bahis çarpanını sıfırla
    game.currentBetMultiplier = 1;
    
    // Kart seçim aşamasını başlat
    startCardSelectPhase(gameId);
}

// Kart seçim aşaması
function startCardSelectPhase(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    game.currentPhase = GAME_PHASE.CARD_SELECT;
    clearTimeout(game.phaseTimer);

    // Round başlangıç bilgisini gönder
    io.to(`game_${gameId}`).emit('game:cardSelectPhase', {
        roundNumber: game.currentRound,
        timeLimit: 12, // Değişiklik burada: 8 -> 12
        blockedMoves: {
            player1: game.players.player1.blockedMoves,
            player2: game.players.player2.blockedMoves
        },
        betMultiplier: game.currentBetMultiplier
    });

    // 12 saniye sonra otomatik sonuç aşamasına geç
    game.phaseTimer = setTimeout(() => {
        if (!game.players.player1.currentMove) {
            game.players.player1.currentMove = 'timeout';
        }
        if (!game.players.player2.currentMove) {
            game.players.player2.currentMove = 'timeout';
        }
        startRevealingPhase(gameId);
    }, 12000); // Değişiklik burada: 8000 -> 12000
}

// Kart gösterim aşaması
function startRevealingPhase(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    game.currentPhase = GAME_PHASE.REVEALING;
    clearTimeout(game.phaseTimer);

    const p1Move = game.players.player1.currentMove || 'timeout';
    const p2Move = game.players.player2.currentMove || 'timeout';

    // Gösterim bilgisini gönder
    io.to(`game_${gameId}`).emit('game:revealingPhase', {
        roundNumber: game.currentRound,
        moves: {
            player1: p1Move,
            player2: p2Move
        }
    });

    // 3 saniye sonra round sonuç aşamasına geç (Değişiklik burada: 2 -> 3)
    game.phaseTimer = setTimeout(() => {
        startRoundResultPhase(gameId);
    }, 3000);
}
// Round sonuç aşaması
function startRoundResultPhase(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    game.currentPhase = GAME_PHASE.ROUND_RESULT;
    clearTimeout(game.phaseTimer);

    const p1Move = game.players.player1.currentMove;
    const p2Move = game.players.player2.currentMove;
    
    const result = determineWinner(p1Move, p2Move);

    // Round sonucunu geçici olarak sakla
    game.tempResult = {
        moves: {
            player1: p1Move,
            player2: p2Move
        },
        winner: result.winner
    };

    // Bu aşamada kazananı güncelle (ama client'a henüz gönderme)
    if (result.winner === 'player1') {
        game.tempWins = {
            player1: game.players.player1.wins + 1,
            player2: game.players.player2.wins
        };
    } else if (result.winner === 'player2') {
        game.tempWins = {
            player1: game.players.player1.wins,
            player2: game.players.player2.wins
        };
    } else {
        game.tempWins = {
            player1: game.players.player1.wins,
            player2: game.players.player2.wins
        };
    }

    // Sonuç bilgisini gönder (burada henüz kazanan skoru güncellenmiyor)
    io.to(`game_${gameId}`).emit('game:roundResultPhase', {
        roundNumber: game.currentRound,
        moves: {
            player1: p1Move,
            player2: p2Move
        },
        result: result,
        // Geçici skor bilgisini gönder
        player1Wins: game.tempWins.player1, 
        player2Wins: game.tempWins.player2
    });

    // 2. ÖNEMLİ DEĞİŞİKLİK: Oyun kazananı kontrolünü burada yapıyoruz
    // Eğer oyun sonlandıysa (biri hedef skora ulaştıysa), oyunu bitir
    if (game.tempWins.player1 >= game.targetWins || game.tempWins.player2 >= game.targetWins) {
        // Önce skoru güncelle
        if (result.winner === 'player1') {
            game.players.player1.wins++;
        } else if (result.winner === 'player2') {
            game.players.player2.wins++;
        }
        
        // 4 saniye sonra oyunu sonlandır
        game.phaseTimer = setTimeout(() => {
            endGame(gameId);
        }, 4000);
    } else {
        // YENİ: Joker haklarını kontrol et
        // Her iki oyuncunun da kullanılabilir jokeri kalmadıysa joker fazını atla
        const player1HasJokers = Object.values(game.players.player1.jokers).some(count => count > 0);
        const player2HasJokers = Object.values(game.players.player2.jokers).some(count => count > 0);
        
        if (!player1HasJokers && !player2HasJokers) {
            // Joker fazını atlayacağımızı bildiren özel mesaj gönder
            io.to(`game_${gameId}`).emit('game:jokerPhaseSkipped', {
                message: "Kullanılabilir joker kalmadı. Joker fazı atlanıyor.",
                roundNumber: game.currentRound
            });
            
            // 4 saniye sonra doğrudan round sonlandırma fazına geç
            game.phaseTimer = setTimeout(() => {
                finalizeRound(gameId);
            }, 4000);
        } else {
            // Joker haklarından en az biri var, normal akışa devam et
            // 4 saniye sonra joker aşamasına geç
            game.phaseTimer = setTimeout(() => {
                startJokerSelectPhase(gameId);
            }, 4000);
        }
    }
}

// Joker seçim aşaması
function startJokerSelectPhase(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    game.currentPhase = GAME_PHASE.JOKER_SELECT;
    clearTimeout(game.phaseTimer);

    // Joker haklarını kontrol et
    const player1HasJokers = Object.values(game.players.player1.jokers).some(count => count > 0);
    const player2HasJokers = Object.values(game.players.player2.jokers).some(count => count > 0);
    
    // Joker fazı başlangıç bilgisini gönder
    io.to(`game_${gameId}`).emit('game:jokerSelectPhase', {
        roundNumber: game.currentRound,
        timeLimit: 10, // Değişiklik burada: 5 -> 10
        availableJokers: {
            player1: game.players.player1.jokers,
            player2: game.players.player2.jokers
        },
        hasJokers: {
            player1: player1HasJokers,
            player2: player2HasJokers
        },
        tempResult: game.tempResult // Geçici sonucu da gönder
    });

    // 10 saniye sonra joker gösterim fazına geç
    game.phaseTimer = setTimeout(() => {
        startJokerRevealPhase(gameId);
    }, 10000);
}

// Joker gösterim aşaması
function startJokerRevealPhase(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    game.currentPhase = GAME_PHASE.JOKER_REVEAL;
    clearTimeout(game.phaseTimer);
    
    // Joker etkilerini uygula
    applyJokerEffects(gameId);
    
    // Joker kullanım durumu bilgisini hazırla
    let jokerUsageStatus = "none"; // Varsayılan: kimse joker kullanmadı
    
    if (game.players.player1.currentJoker && !game.players.player2.currentJoker) {
        jokerUsageStatus = "green"; // Sadece yeşil takım (player1) joker kullandı
    } else if (!game.players.player1.currentJoker && game.players.player2.currentJoker) {
        jokerUsageStatus = "red"; // Sadece kırmızı takım (player2) joker kullandı
    } else if (game.players.player1.currentJoker && game.players.player2.currentJoker) {
        jokerUsageStatus = "both"; // Her iki takım da joker kullandı
    }
    
    // Joker gösterim bilgisini gönder
    io.to(`game_${gameId}`).emit('game:jokerRevealPhase', {
        roundNumber: game.currentRound,
        jokers: {
            player1: game.players.player1.currentJoker,
            player2: game.players.player2.currentJoker
        },
        jokerUsageStatus: jokerUsageStatus, // Yeni: Joker kullanım durumu
        nextRoundBlockedMoves: {
            player1: game.players.player1.nextRoundBlockedMoves,
            player2: game.players.player2.nextRoundBlockedMoves
        },
        betMultiplier: game.currentBetMultiplier
    });

    // 5 saniye sonra round sonunu işle (Değişiklik burada: 2000 -> 5000)
    game.phaseTimer = setTimeout(() => {
        finalizeRound(gameId);
    }, 5000);
}

// Round sonuçlandırma
function finalizeRound(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    game.currentPhase = GAME_PHASE.ROUND_END;
    clearTimeout(game.phaseTimer);

    // Geçici sonucu al
    const { moves, winner } = game.tempResult;

    // Round sonucunu kaydet
    game.roundResults.push({
        round: game.currentRound,
        moves: moves,
        winner: winner,
        betMultiplier: game.currentBetMultiplier,
        jokers: {
            player1: game.players.player1.currentJoker,
            player2: game.players.player2.currentJoker
        }
    });

    // Kazananı güncelle (joker aşamasından sonra kesinleştirme)
    if (winner === 'player1' && game.players.player1.wins < game.tempWins.player1) {
        game.players.player1.wins++;
    } else if (winner === 'player2' && game.players.player2.wins < game.tempWins.player2) {
        game.players.player2.wins++;
    }

    // Final sonucunu gönder
    io.to(`game_${gameId}`).emit('game:roundEndPhase', {
        roundNumber: game.currentRound,
        winner: winner,
        player1Wins: game.players.player1.wins,
        player2Wins: game.players.player2.wins,
        betMultiplier: game.currentBetMultiplier,
        jokers: {
            player1: game.players.player1.currentJoker,
            player2: game.players.player2.currentJoker
        }
    });

    // Geçici sonucu ve geçici skorları temizle
    delete game.tempResult;
    delete game.tempWins;

    // 5 saniye sonra yeni round başlat (Değişiklik burada: 2000 -> 5000)
    setTimeout(() => startNewRound(gameId), 5000);
}

// Joker etkilerini uygula
function applyJokerEffects(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    const { player1, player2 } = game.players;
    
    // İlk başta temizleme işlemi yap
    // ÖNEMLİ: Önce dizileri sıfırlıyoruz, sonra sadece kullanılan jokerlere göre dolduruyoruz
    player1.nextRoundBlockedMoves = [];
    player2.nextRoundBlockedMoves = [];
    
    console.log("Joker etkileri uygulanıyor - Oyuncuların hamleleri:", {
        player1Move: player1.currentMove,
        player2Move: player2.currentMove,
        player1Joker: player1.currentJoker,
        player2Joker: player2.currentJoker
    });
    
    // Bahis jokeri kontrolü
    if (player1.currentJoker === JOKER_TYPES.BET || player2.currentJoker === JOKER_TYPES.BET) {
        game.currentBetMultiplier *= 2;
        console.log("Bahis jokeri kullanıldı - Yeni çarpan:", game.currentBetMultiplier);
    }
    
    // Bloke jokeri kontrolü - Player 1 bloke jokeri kullandıysa
    if (player1.currentJoker === JOKER_TYPES.BLOCK) {
        // Player 1 bloke jokeri kullandı, player 2'nin hamlelerini bloke et
        const allMoves = ['rock', 'paper', 'scissors'];
        player2.nextRoundBlockedMoves = allMoves
            .sort(() => Math.random() - 0.5)
            .slice(0, 2);
            
        console.log("Player 1 BLOCK jokeri kullandı. Player 2'nin bloke edilen hamleleri:", player2.nextRoundBlockedMoves);
    }
    
    // Player 2 bloke jokeri kullandıysa
    if (player2.currentJoker === JOKER_TYPES.BLOCK) {
        // Player 2 bloke jokeri kullandı, player 1'in hamlelerini bloke et
        const allMoves = ['rock', 'paper', 'scissors'];
        player1.nextRoundBlockedMoves = allMoves
            .sort(() => Math.random() - 0.5)
            .slice(0, 2);
            
        console.log("Player 2 BLOCK jokeri kullandı. Player 1'in bloke edilen hamleleri:", player1.nextRoundBlockedMoves);
    }
    
    // Kanca jokeri kontrolü - Player 1 kanca jokeri kullandıysa
    if (player1.currentJoker === JOKER_TYPES.HOOK && player2.currentMove) {
        // Player 1 kanca jokeri kullandı, player 2'nin mevcut hamlesini bloke et
        if (!player2.nextRoundBlockedMoves.includes(player2.currentMove)) {
            player2.nextRoundBlockedMoves.push(player2.currentMove);
            console.log("Player 1 HOOK jokeri kullandı. Player 2'nin bloke edilen hamlesi:", player2.currentMove);
        }
    }
    
    // Player 2 kanca jokeri kullandıysa
    if (player2.currentJoker === JOKER_TYPES.HOOK && player1.currentMove) {
        // Player 2 kanca jokeri kullandı, player 1'in mevcut hamlesini bloke et
        if (!player1.nextRoundBlockedMoves.includes(player1.currentMove)) {
            player1.nextRoundBlockedMoves.push(player1.currentMove);
            console.log("Player 2 HOOK jokeri kullandı. Player 1'in bloke edilen hamlesi:", player1.currentMove);
        }
    }
    
    // Tüm client'lara güncel bloke bilgilerini göndermek için konsola yazdır
    console.log("Joker etkileri uygulandıktan sonra bloke durumları:", {
        player1BlockedMoves: player1.nextRoundBlockedMoves,
        player2BlockedMoves: player2.nextRoundBlockedMoves
    });
}
// Oyun bitirme fonksiyonu
async function endGame(gameId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    // Oyun sonucunu hesapla
    const finalResult = calculateGameResult(game);
    
    try {
        // Oyun kaydını güncelle
        await pool.execute(
            'UPDATE games SET status = ?, winner = ?, ended_at = NOW() WHERE game_id = ?',
            ['COMPLETED', finalResult.winner, gameId]
        );

        // İstatistikleri güncelle
        const { player1Wins, player2Wins, draws } = finalResult.stats;
        
        // İlk oyuncu istatistiklerini güncelle
        await pool.execute(
            'UPDATE statistics SET total_wins = total_wins + ?, total_losses = total_losses + ?, win_rate = (total_wins / (total_wins + total_losses)) * 100 WHERE user_id = ?',
            [player1Wins, player2Wins, game.players.player1.id]
        );

        // İkinci oyuncu istatistiklerini güncelle
        await pool.execute(
            'UPDATE statistics SET total_wins = total_wins + ?, total_losses = total_losses + ?, win_rate = (total_wins / (total_wins + total_losses)) * 100 WHERE user_id = ?',
            [player2Wins, player1Wins, game.players.player2.id]
        );

        // Altın ödülünü ver (kazanan oyuncuya bet amount * 2)
        if (finalResult.winner !== 'draw') {
            await pool.execute(
                'UPDATE users SET current_gold = current_gold + ? WHERE user_id = ?',
                [game.betAmount * 2, finalResult.winner]
            );
        } else {
            // Beraberlik durumunda her iki oyuncuya bet amount geri ver
            await pool.execute(
                'UPDATE users SET current_gold = current_gold + ? WHERE user_id IN (?, ?)',
                [game.betAmount, game.players.player1.id, game.players.player2.id]
            );
        }

    } catch (error) {
        console.error('Game end database update error:', error);
    }

    // Sonucu oyunculara bildir
    io.to(`game_${gameId}`).emit('game:end', finalResult);
    
    // Oyunu aktif oyunlardan kaldır
    activeGames.delete(gameId);
}

// Kazananı belirleme fonksiyonu
function determineWinner(move1, move2) {
    // Timeout kontrolü
    if (move1 === 'timeout' && move2 === 'timeout') {
        return { winner: 'draw' };
    } else if (move1 === 'timeout') {
        return { winner: 'player2' };
    } else if (move2 === 'timeout') {
        return { winner: 'player1' };
    }

    // Normal hamle kontrolü
    if (move1 === move2) {
        return { winner: 'draw' };
    }

    const winConditions = {
        rock: 'scissors',
        paper: 'rock',
        scissors: 'paper'
    };

    if (winConditions[move1] === move2) {
        return { winner: 'player1' };
    } else {
        return { winner: 'player2' };
    }
}

// Oyun sonucunu hesaplama
// Oyun sonucunu hesaplama (devam)
function calculateGameResult(game) {
    const { player1, player2 } = game.players;
    let winner;

    if (player1.wins > player2.wins) {
        winner = player1.id;
    } else if (player2.wins > player1.wins) {
        winner = player2.id;
    } else {
        winner = 'draw';
    }

    const drawCount = game.roundResults ? 
        game.roundResults.filter(r => r.winner === 'draw').length : 0;

    return {
        winner,
        stats: {
            player1Wins: player1.wins,
            player2Wins: player2.wins,
            draws: drawCount
        },
        totalRounds: game.currentRound
    };
}

// Bekleme listesinden oyuncu temizleme
function cleanupWaitingPlayer(socketId, league) {
    const waitingPlayersInLeague = waitingPlayers.get(league) || [];
    waitingPlayers.set(league, 
        waitingPlayersInLeague.filter(p => p.socketId !== socketId)
    );
}

// Bağlantı kopması işleme
function handleDisconnect(socket) {
    const player = activePlayers.get(socket.id);
    if (!player) return;

    console.log('Disconnect connection:', socket.id);

    // Aktif oyuncu listesinden çıkar
    activePlayers.delete(socket.id);

    // Bekleme listesinden çıkar
    for (const [league, players] of waitingPlayers.entries()) {
        waitingPlayers.set(league, 
            players.filter(p => p.socketId !== socket.id)
        );
    }

    // Aktif oyunları kontrol et ve gerekirse ceza uygula
    for (const [gameId, game] of activeGames.entries()) {
        // Oyuncunun ID'sini kontrol et
        if (game.players.player1.id === player.userId || game.players.player2.id === player.userId) {
            handleGameDisconnect(gameId, player.userId);
        }
    }
}

// Oyun bağlantı kopması işleme
async function handleGameDisconnect(gameId, userId) {
    const game = activeGames.get(gameId);
    if (!game) return;

    // Oyunu sonlandır ve ceza uygula
    const isPlayer1 = userId === game.players.player1.id;
    const winner = isPlayer1 ? game.players.player2.id : game.players.player1.id;
    
    try {
        // Oyunu güncelle
        await pool.execute(
            'UPDATE games SET status = ?, winner = ?, ended_at = NOW() WHERE game_id = ?',
            ['DISCONNECTED', winner, gameId]
        );

        // Ceza uygula
        await pool.execute(
            'INSERT INTO penalties (user_id, type, amount, reason, created_at) VALUES (?, ?, ?, ?, NOW())',
            [userId, 'DISCONNECT', game.betAmount, 'Game disconnection penalty']
        );

        // Kazanan oyuncuya ödül ver
        await pool.execute(
            'UPDATE users SET current_gold = current_gold + ? WHERE user_id = ?',
            [game.betAmount * 2, winner]
        );

    } catch (error) {
        console.error('Game disconnect handling error:', error);
    }

    // Diğer oyuncuya bildir
    io.to(`game_${gameId}`).emit('game:disconnected', {
        disconnectedPlayer: userId,
        winner: winner
    });

    // Oyunu kapat
    activeGames.delete(gameId);
}

// Yardımcı fonksiyonlar
function generateGameId() {
    return 'game_' + Math.random().toString(36).substr(2, 9);
}

// İlk oyun durumunu oluştur
function createInitialGameState(gameId, player1Id, player2Id, betAmount, targetWins) {
    return {
        gameId,
        currentPhase: GAME_PHASE.PREPARATION,
        players: {
            player1: { 
                id: player1Id, 
                wins: 0,
                isReady: false,
                jokers: {
                    block: targetWins === 5 ? 2 : 1,
                    hook: targetWins === 5 ? 2 : 1,
                    bet: targetWins === 5 ? 2 : 1
                },
                currentMove: null,
                currentJoker: null,
                lastMove: null,
                blockedMoves: [],
                nextRoundBlockedMoves: []
            },
            player2: { 
                id: player2Id, 
                wins: 0,
                isReady: false,
                jokers: {
                    block: targetWins === 5 ? 2 : 1,
                    hook: targetWins === 5 ? 2 : 1,
                    bet: targetWins === 5 ? 2 : 1
                },
                currentMove: null,
                currentJoker: null,
                lastMove: null,
                blockedMoves: [],
                nextRoundBlockedMoves: []
            }
        },
        currentRound: 0,
        currentBetMultiplier: 1,
        betAmount: betAmount,
        targetWins: targetWins,
        status: 'PLAYING',
        roundResults: [],
        preparationTimer: null,
        phaseTimer: null
    };
}

// Server'ı başlat
const PORT = process.env.PORT || 3000;
httpServer.listen(PORT, () => {
    console.log(`Socket server running on port ${PORT}`);
});