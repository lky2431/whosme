BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "game_history" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "roomId" bigint NOT NULL,
    "round" bigint NOT NULL,
    "completedAt" timestamp without time zone NOT NULL,
    "viewJson" text NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "game_history_user_room_round_unique" ON "game_history" USING btree ("userId", "roomId", "round");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "player_profile" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "displayName" text NOT NULL,
    "avatarIndex" bigint NOT NULL,
    "avatarImage" text
);

-- Indexes
CREATE UNIQUE INDEX "player_profile_user_unique" ON "player_profile" USING btree ("userId");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "saved_seat" (
    "id" bigserial PRIMARY KEY,
    "userId" text NOT NULL,
    "roomId" bigint NOT NULL,
    "playerId" text NOT NULL,
    "joinedAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "saved_seat_user_room_unique" ON "saved_seat" USING btree ("userId", "roomId");


--
-- MIGRATION VERSION FOR yourname
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('yourname', '20261010100646367', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261010100646367', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod', '20260129180959368', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129180959368', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_idp
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_idp', '20260213194423028', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260213194423028', "timestamp" = now();

--
-- MIGRATION VERSION FOR serverpod_auth_core
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('serverpod_auth_core', '20260129181112269', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20260129181112269', "timestamp" = now();


COMMIT;
