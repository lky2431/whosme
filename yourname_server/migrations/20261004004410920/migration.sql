BEGIN;

--
-- ACTION CREATE TABLE
--
CREATE TABLE "game_room" (
    "id" bigserial PRIMARY KEY,
    "code" text NOT NULL,
    "stateJson" text NOT NULL,
    "expiresAt" timestamp without time zone NOT NULL
);

-- Indexes
CREATE UNIQUE INDEX "game_room_code_unique" ON "game_room" USING btree ("code");

--
-- ACTION CREATE TABLE
--
CREATE TABLE "party_question" (
    "id" bigserial PRIMARY KEY,
    "slug" text NOT NULL,
    "category" text NOT NULL,
    "prompt" text NOT NULL,
    "choices" json NOT NULL,
    "enabled" boolean NOT NULL DEFAULT true
);

-- Indexes
CREATE UNIQUE INDEX "party_question_slug_unique" ON "party_question" USING btree ("slug");


--
-- MIGRATION VERSION FOR yourname
--
INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
    VALUES ('yourname', '20261004004410920', now())
    ON CONFLICT ("module")
    DO UPDATE SET "version" = '20261004004410920', "timestamp" = now();

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
