# Lockout plan

@plan lockout@abc123
@scope src/**

## Twice

@scope lib/**
@req far

## Twice

@scope src/a/**
@decision -bad

## Empty

@scope ,
@decision other
