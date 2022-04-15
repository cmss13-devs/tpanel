# Tpanel

## Overview

This is a simple webapp meant to allow defining and maintaining code revisions made from multiple remote branches more easily. This is done by rebasing each tip in succession onto a common branch. In SS13 community, we use this for "testmerging", which is the action of running testing build live with various contributor changesets.

This is a rough draft and work in progress.

## Features

 * Basic User Auth via email:pass - created manually on CLI
 * Creating/Viewing "TestMixes" definitions, a list of remote/branches with update info
 * Fetching and building these via git calls to a local work directory
 * Build button to call `docker build` for image creation
 * Streaming console output during operations
 * Leverages Phoenix LiveViews and PubSub for reactivity & concurrent use

## Deps

 * Phoenix 1.6+
 * A PostgreSQL 10+ Server
 * Docker client and perm for running user (if using build button)
 * Node 16+ for PostCSS/Tailwind

## Quick Start

 * mix deps.get
 * mix ecto.setup
 * run in debug with `iex -S mix phx.server` or [check phoenix deployment guide](https://hexdocs.pm/phoenix/deployment.html)
 * mix tpanel.new\_user someemail@example.com
 * hit up `http://localhost:4000`

Alternatively use the docker deployment with the provided Dockerfile / docker-compose.yml

## High level overview
 
 * TestMix and Branch models are managed together through GitTools module
 * Runtime funcitonality is handled by MixServer, a GenServer tasked with carrying out actual process
 * MixServer excutes tasks with Rambo library and streams output via Phoenix PubSub
 * To avoid concurrent access, they are spawned by a DynamicSupervisor, one per mix
 * The BranchLiveView displays and allows to edit Branches within a TestMix
 * The MixServerLiveView allows interaction with the MixServer, and displaying output

## Current issues

 * Rough feature wise, no config, build is not modular
 * No queuing beyond GenServer internal queue: if you click Mix/Build 10 times, it'll happen 10 times
 * Console display should be a proper fixed, resizeable, scrollable div but long-term browser issues with flex-col-reverse made this complicated
 * Directly sending terminal output via PubSub means linewrap doesn't match eg. git output
 * Lacking tests and fixtures
 * Probably more

