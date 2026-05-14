PRAGMA foreign_keys = ON;

-- Festival difffusion module.
-- File-name convention: columns ending in _file store only the file name (unique
-- per table); the application constructs full URLs (e.g. presigned download).
-- Enum convention: CHECK constraints on columns, no lookup tables.

BEGIN;

-- ---------------------------------------------------------------------------
-- 4.1  Editions, branding & blog
-- ---------------------------------------------------------------------------

CREATE TABLE blog_tags (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL UNIQUE
);

CREATE TABLE blog_posts (
  id INTEGER PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE,
  summary TEXT,
  body TEXT,
  published_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE blog_post_tags (
  post_id INTEGER NOT NULL,
  tag_id INTEGER NOT NULL,
  PRIMARY KEY (post_id, tag_id),
  FOREIGN KEY (post_id) REFERENCES blog_posts(id) ON DELETE CASCADE,
  FOREIGN KEY (tag_id) REFERENCES blog_tags(id) ON DELETE CASCADE
);

CREATE TABLE festival_editions (
  id INTEGER PRIMARY KEY,
  year INTEGER NOT NULL UNIQUE,
  title TEXT,
  theme TEXT,
  custom_logo_file TEXT,
  hero_image_file TEXT,
  short_description TEXT,
  long_description TEXT,
  secondary_image_file TEXT,
  accent_image_file TEXT,
  main_color TEXT,
  secondary_color TEXT,
  accent_color TEXT,
  after_video_file TEXT,
  blog_tag_id INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (blog_tag_id) REFERENCES blog_tags(id) ON DELETE SET NULL
);

CREATE TABLE festival_edition_gallery_photos (
  id INTEGER PRIMARY KEY,
  edition_id INTEGER NOT NULL,
  photo_file TEXT NOT NULL UNIQUE,
  caption TEXT,
  sort_order INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 4.2  Sections & activities
-- ---------------------------------------------------------------------------

CREATE TABLE festival_sections (
  id INTEGER PRIMARY KEY,
  edition_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE
);

CREATE TABLE festival_activities (
  id INTEGER PRIMARY KEY,
  section_id INTEGER NOT NULL,
  title TEXT,
  description TEXT,
  activity_type TEXT NOT NULL CHECK (activity_type IN (
    'talk_panel', 'talk_keynote', 'installation', 'workshop',
    'social_tour', 'social_dinner', 'social_concert', 'staff_roundup'
  )),
  audience TEXT NOT NULL CHECK (audience IN ('public', 'guests', 'staff')),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (section_id) REFERENCES festival_sections(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 4.3  Festival locations & staff
-- ---------------------------------------------------------------------------

CREATE TABLE festival_volunteers (
  id INTEGER PRIMARY KEY,
  edition_id INTEGER NOT NULL,
  profile_id INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (edition_id, profile_id),
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE RESTRICT
);

CREATE TABLE festival_locations (
  id INTEGER PRIMARY KEY,
  edition_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  address TEXT,
  description TEXT,
  coordinator_id INTEGER,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE,
  FOREIGN KEY (coordinator_id) REFERENCES festival_volunteers(id) ON DELETE SET NULL
);

CREATE TABLE festival_staff_members (
  edition_id INTEGER NOT NULL,
  member_id INTEGER NOT NULL,
  PRIMARY KEY (edition_id, member_id),
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE,
  FOREIGN KEY (member_id) REFERENCES members(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 4.4  Guests
-- ---------------------------------------------------------------------------

CREATE TABLE festival_guests (
  id INTEGER PRIMARY KEY,
  edition_id INTEGER NOT NULL,
  profile_id INTEGER NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES profiles(id) ON DELETE RESTRICT
);

CREATE TABLE festival_guest_roles (
  guest_id INTEGER NOT NULL,
  role TEXT NOT NULL CHECK (role IN ('speaker', 'workshop_org', 'artist', 'other')),
  PRIMARY KEY (guest_id, role),
  FOREIGN KEY (guest_id) REFERENCES festival_guests(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 4.5  Program
-- ---------------------------------------------------------------------------

CREATE TABLE festival_program (
  id INTEGER PRIMARY KEY,
  edition_id INTEGER NOT NULL,
  location_id INTEGER NOT NULL,
  activity_id INTEGER NOT NULL,
  starts_at TEXT NOT NULL,
  ends_at TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE,
  FOREIGN KEY (location_id) REFERENCES festival_locations(id) ON DELETE RESTRICT,
  FOREIGN KEY (activity_id) REFERENCES festival_activities(id) ON DELETE RESTRICT
);

CREATE TABLE festival_program_presenters (
  program_id INTEGER NOT NULL,
  guest_id INTEGER NOT NULL,
  PRIMARY KEY (program_id, guest_id),
  FOREIGN KEY (program_id) REFERENCES festival_program(id) ON DELETE CASCADE,
  FOREIGN KEY (guest_id) REFERENCES festival_guests(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 4.6  Sponsors & discount locations
-- ---------------------------------------------------------------------------

CREATE TABLE festival_sponsors (
  id INTEGER PRIMARY KEY,
  edition_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  sponsorship_type TEXT NOT NULL CHECK (sponsorship_type IN (
    'media', 'institution', 'catering', 'publishing', 'other'
  )),
  sponsorship_level TEXT NOT NULL CHECK (sponsorship_level IN (
    'whisperer', 'charmer', 'loudspeaker', 'difffusion_voice'
  )),
  logo_file TEXT,
  website TEXT,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE
);

CREATE TABLE festival_sponsor_discount_locations (
  id INTEGER PRIMARY KEY,
  sponsor_id INTEGER NOT NULL,
  name TEXT NOT NULL,
  address TEXT,
  discount_percent INTEGER NOT NULL CHECK (discount_percent BETWEEN 1 AND 100),
  redeem_max INTEGER NOT NULL CHECK (redeem_max >= 1),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (sponsor_id) REFERENCES festival_sponsors(id) ON DELETE CASCADE
);

-- ---------------------------------------------------------------------------
-- 4.7  Tickets & discount redeemings
-- ---------------------------------------------------------------------------

CREATE TABLE festival_tickets (
  id INTEGER PRIMARY KEY,
  edition_id INTEGER NOT NULL,
  holder_profile_id INTEGER NOT NULL,
  code TEXT NOT NULL,
  guest_count INTEGER NOT NULL DEFAULT 0 CHECK (guest_count BETWEEN 0 AND 5),
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE (edition_id, code),
  FOREIGN KEY (edition_id) REFERENCES festival_editions(id) ON DELETE CASCADE,
  FOREIGN KEY (holder_profile_id) REFERENCES profiles(id) ON DELETE RESTRICT
);

CREATE TABLE festival_discount_redeemings (
  id INTEGER PRIMARY KEY,
  ticket_id INTEGER NOT NULL,
  discount_location_id INTEGER NOT NULL,
  redeemed_at TEXT NOT NULL,
  UNIQUE (ticket_id, discount_location_id),
  FOREIGN KEY (ticket_id) REFERENCES festival_tickets(id) ON DELETE CASCADE,
  FOREIGN KEY (discount_location_id) REFERENCES festival_sponsor_discount_locations(id) ON DELETE RESTRICT
);

-- Enforce: total redeemings per discount_location cannot exceed its redeem_max.
CREATE TRIGGER trg_discount_redeemings_limit
BEFORE INSERT ON festival_discount_redeemings
FOR EACH ROW
WHEN (
  SELECT COUNT(*)
  FROM festival_discount_redeemings
  WHERE discount_location_id = NEW.discount_location_id
) >= (
  SELECT redeem_max
  FROM festival_sponsor_discount_locations
  WHERE id = NEW.discount_location_id
)
BEGIN
  SELECT RAISE(ABORT, 'redeem_max reached for this discount location');
END;

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------

CREATE INDEX idx_festival_edition_gallery_edition_id ON festival_edition_gallery_photos(edition_id);
CREATE INDEX idx_festival_sections_edition_id ON festival_sections(edition_id);
CREATE INDEX idx_festival_activities_section_id ON festival_activities(section_id);
CREATE INDEX idx_festival_volunteers_profile_id ON festival_volunteers(profile_id);
CREATE INDEX idx_festival_locations_edition_id ON festival_locations(edition_id);
CREATE INDEX idx_festival_locations_coordinator_id ON festival_locations(coordinator_id);
CREATE INDEX idx_festival_guests_edition_id ON festival_guests(edition_id);
CREATE INDEX idx_festival_guests_profile_id ON festival_guests(profile_id);
CREATE INDEX idx_festival_program_edition_id ON festival_program(edition_id);
CREATE INDEX idx_festival_program_location_id ON festival_program(location_id);
CREATE INDEX idx_festival_program_activity_id ON festival_program(activity_id);
CREATE INDEX idx_festival_program_starts_at ON festival_program(starts_at);
CREATE INDEX idx_festival_sponsors_edition_id ON festival_sponsors(edition_id);
CREATE INDEX idx_festival_sponsor_discount_locs_sponsor_id ON festival_sponsor_discount_locations(sponsor_id);
CREATE INDEX idx_festival_tickets_edition_id ON festival_tickets(edition_id);
CREATE INDEX idx_festival_tickets_holder_profile_id ON festival_tickets(holder_profile_id);
CREATE INDEX idx_festival_discount_redeemings_ticket_id ON festival_discount_redeemings(ticket_id);
CREATE INDEX idx_festival_discount_redeemings_location_id ON festival_discount_redeemings(discount_location_id);
CREATE INDEX idx_blog_post_tags_tag_id ON blog_post_tags(tag_id);

COMMIT;
