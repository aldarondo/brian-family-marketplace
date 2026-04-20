---
name: new-releases
description: Discover and queue new movies and TV shows for Jellyfin. Use this skill whenever the user asks about new movies, new shows, recent releases, what's out this month, what's new to watch, or wants to add something that just came out. Trigger even if they just say "what movies are out?" or "anything new?"
---

# New Releases — Jellyfin

Surface recent movies and TV from the past 30–90 days and queue selected ones to Radarr/Sonarr.

## Conversation flow

### Step 1 — Discover

When the user asks about new content, call both discovery tools immediately (no need to ask first):

```
discover_new_movies(days=30, genre=<if mentioned>)
discover_new_tv(days=30, genre=<if mentioned>)
```

Use `days=60` or `days=90` if they say "past couple months" or want a broader window.

Present results as two compact numbered lists — **include the overview for every item**, not just the title:

```
🎬 *New Movies* (N available)

1. *Title* (Year) · ⭐ 7.8
   One-sentence overview.

2. *Title* (Year) · ⭐ 8.1
   One-sentence overview.

📺 *New TV Shows* (N available)

1. *Title* (Year) · ⭐ 7.5
   One-sentence overview.
```

Then ask: "Which ones do you want to add?"

### Step 2 — Queue

The user will reply naturally — "1 and 3", "the first movie", "Silo", "all of them", etc. Match their picks to the TMDB IDs from Step 1. Then call:

```
queue_movies(tmdb_ids=[...])      # for selected movies
queue_tv_shows(tmdb_ids=[...])    # for selected TV shows
```

Report back cleanly:
- ✅ Title — queued
- ⏭ Title — already in library
- ❌ Title — error (brief reason)

## Genre filter

If the user specifies a genre, pass it to the discovery tools:
`action, adventure, animation, comedy, crime, drama, fantasy, horror, mystery, romance, sci-fi, thriller`

## Handling follow-ups

If the user asks "what about older ones?" or "anything from before this year?", switch to the old-releases flow (use `discover_old_movies` / `discover_old_tv`).

If the user says "show me more", call the discovery tools again with `days=90` or a broader filter.
