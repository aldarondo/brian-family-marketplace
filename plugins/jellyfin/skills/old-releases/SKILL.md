---
name: old-releases
description: Discover acclaimed older movies and TV shows not yet in the Jellyfin library. Use this skill whenever the user asks about classic films, older shows, highly-rated older content, or wants suggestions from a specific decade or era. Trigger for phrases like "what are some great 80s movies?", "recommend acclaimed sci-fi", "old shows I should watch", "what are the best dramas?", or "what classics am I missing?"
---

# Old Releases — Jellyfin

Surface top-rated older content (2+ years old) not yet in the Jellyfin library and queue selections.

## Conversation flow

### Step 1 — Discover

Call both discovery tools immediately with any filters the user mentioned:

```
discover_old_movies(genre=<if mentioned>, decade=<if mentioned>, min_rating=7.5, count=20)
discover_old_tv(genre=<if mentioned>, decade=<if mentioned>, min_rating=7.5, count=20)
```

**Decade**: if the user says "80s", "nineties", "turn of the century", etc. — map to `50s`, `60s`, `70s`, `80s`, `90s`, `00s`, `10s`.

Present results as compact numbered lists with overviews — same format as new-releases:

```
🎬 *Acclaimed Movies* (N available)

1. *Title* (Year) · ⭐ 8.4
   One-sentence overview.

📺 *Acclaimed TV Shows* (N available)

1. *Title* (Year) · ⭐ 8.1
   One-sentence overview.
```

Ask: "Any of these look good?"

### Step 2 — Queue

Match natural-language picks to TMDB IDs from Step 1, then call:

```
queue_movies(tmdb_ids=[...])
queue_tv_shows(tmdb_ids=[...])
```

Report results:
- ✅ Title — queued
- ⏭ Title — already in library  
- ❌ Title — error (brief reason)

## Filters

| What user says | Parameter |
|---|---|
| "sci-fi", "horror", "drama" | `genre` |
| "80s", "nineties", "2000s" | `decade` |
| "highly rated", "only the best" | raise `min_rating` to 8.0+ |
| "show me more" | increase `count` or drop filters |

## Only movies or only TV

If the user only asks about movies ("classic movies", "great films"), only call `discover_old_movies`. Same for TV. Call both only when the request is ambiguous or they want both.
