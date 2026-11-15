# Lockout plan

@plan lockout@abc123
@scope src/**, !src/secret/**

## Lock the account

@scope src/auth/**
@decision lock-record

## Tidy the cache

@scope src/cache/**
Remove the dead code.
