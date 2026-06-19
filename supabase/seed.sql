-- Xtraaplywood seed data
-- Run this after schema.sql in the Supabase SQL editor.
-- Safe to re-run: inserts use ON CONFLICT updates where practical.

begin;

-- Categories --------------------------------------------------------------
with categories_data(name, slug) as (
  values
    ('Plywood', 'plywood'),
    ('Block Board', 'blockboard'),
    ('Laminates', 'laminate'),
    ('Flush Doors', 'door'),
    ('Hardware', 'hardware'),
    ('MDF / HDF', 'mdf')
)
insert into public.product_categories (name, slug)
select name, slug
from categories_data
on conflict (slug) do update
set name = excluded.name;

-- Products ----------------------------------------------------------------
with products_data(category_slug, name, slug, description, grade, points_per_scan, stock_status) as (
  values
    ('plywood', 'BWR Plywood', 'bwr-plywood', 'Boiling water resistant plywood for furniture, paneling, and interior work.', 'BWR', 40, 'in_stock'),
    ('plywood', 'BWP Plywood', 'bwp-plywood', 'Boiling waterproof plywood suited for kitchens, bathrooms, and wet areas.', 'BWP', 55, 'in_stock'),
    ('plywood', 'Marine Plywood', 'marine-plywood', 'Premium marine-grade plywood with void-free construction and high durability.', 'Marine', 70, 'in_stock'),
    ('plywood', 'Commercial Ply', 'commercial-ply', 'Economical general-purpose plywood for packaging, interiors, and backing work.', 'Commercial', 25, 'in_stock'),
    ('plywood', 'Film Face Ply', 'film-face-ply', 'Phenolic film-faced shuttering plywood for repeated formwork use.', 'BWP', 50, 'limited'),
    ('plywood', 'Flexi Plywood', 'flexi-plywood', 'Bendable plywood for curved furniture, decorative work, and custom designs.', 'Commercial', 45, 'enquire'),
    ('blockboard', 'Block Board 19mm', 'block-board-19mm', 'Timber-core block board for shelves, tables, and general furniture applications.', 'BWR', 50, 'in_stock'),
    ('blockboard', 'Block Board 25mm', 'block-board-25mm', 'Heavy-duty block board for stronger furniture and structural applications.', 'BWR', 60, 'in_stock'),
    ('blockboard', 'Flush Block Board', 'flush-block-board', 'Smooth, even block board often used in flush-door manufacturing.', 'Commercial', 35, 'in_stock'),
    ('laminate', 'Matte Laminate', 'matte-laminate', 'Scratch-resistant matte laminates with a wide range of decorative finishes.', 'ISI', 20, 'in_stock'),
    ('laminate', 'Gloss Laminate', 'gloss-laminate', 'High-gloss laminate suited for wardrobes, modular kitchens, and feature panels.', 'ISI', 20, 'in_stock'),
    ('laminate', 'Woodgrain Laminate', 'woodgrain-laminate', 'Natural wood-look decorative laminate in oak, teak, walnut, and more.', 'ISI', 22, 'in_stock'),
    ('laminate', 'Textured Laminate', 'textured-laminate', 'Embossed laminates with fabric, stone, and abstract textured finishes.', 'ISI', 25, 'limited'),
    ('door', 'Solid Core Door', 'solid-core-door', 'Factory-finished solid core flush door with standard and custom sizing.', 'ISI', 80, 'in_stock'),
    ('door', 'Hollow Core Door', 'hollow-core-door', 'Lightweight interior door option with dependable daily-use performance.', 'Commercial', 50, 'in_stock'),
    ('hardware', 'Cabinet Hardware', 'cabinet-hardware', 'Hinges, handles, drawer channels, and cabinet accessories from trusted brands.', 'ISI', 15, 'in_stock'),
    ('hardware', 'Structural Fixings', 'structural-fixings', 'Anchor bolts, screws, brackets, and other structural fixing solutions.', 'ISI', 10, 'in_stock'),
    ('mdf', 'MDF 18mm', 'mdf-18mm', 'Smooth MDF board for cabinetry, modular kitchens, and machine-cut furniture.', 'ISI', 35, 'in_stock')
)
insert into public.products (category_id, name, slug, description, grade, points_per_scan, stock_status, is_active)
select
  c.id,
  p.name,
  p.slug,
  p.description,
  p.grade,
  p.points_per_scan,
  p.stock_status,
  true
from products_data p
join public.product_categories c on c.slug = p.category_slug
on conflict (slug) do update
set
  category_id = excluded.category_id,
  name = excluded.name,
  description = excluded.description,
  grade = excluded.grade,
  points_per_scan = excluded.points_per_scan,
  stock_status = excluded.stock_status,
  is_active = excluded.is_active;

-- Variants ----------------------------------------------------------------
with variants_data(product_slug, label, sku) as (
  values
    ('bwr-plywood', '6mm', 'XP-BWR-6'),
    ('bwr-plywood', '9mm', 'XP-BWR-9'),
    ('bwr-plywood', '12mm', 'XP-BWR-12'),
    ('bwr-plywood', '18mm', 'XP-BWR-18'),
    ('bwp-plywood', '12mm', 'XP-BWP-12'),
    ('bwp-plywood', '18mm', 'XP-BWP-18'),
    ('bwp-plywood', '25mm', 'XP-BWP-25'),
    ('marine-plywood', '12mm', 'XP-MAR-12'),
    ('marine-plywood', '18mm', 'XP-MAR-18'),
    ('marine-plywood', '25mm', 'XP-MAR-25'),
    ('commercial-ply', '6mm', 'XP-COM-6'),
    ('commercial-ply', '9mm', 'XP-COM-9'),
    ('commercial-ply', '12mm', 'XP-COM-12'),
    ('film-face-ply', '12mm', 'XP-FFP-12'),
    ('film-face-ply', '18mm', 'XP-FFP-18'),
    ('flexi-plywood', '3mm', 'XP-FLX-3'),
    ('flexi-plywood', '6mm', 'XP-FLX-6'),
    ('block-board-19mm', '19mm', 'XP-BB19-19'),
    ('block-board-25mm', '25mm', 'XP-BB25-25'),
    ('flush-block-board', '19mm', 'XP-FBB-19'),
    ('flush-block-board', '25mm', 'XP-FBB-25'),
    ('matte-laminate', '0.8mm', 'XP-ML-08'),
    ('matte-laminate', '1mm', 'XP-ML-10'),
    ('gloss-laminate', '0.8mm', 'XP-GL-08'),
    ('gloss-laminate', '1mm', 'XP-GL-10'),
    ('woodgrain-laminate', '0.8mm', 'XP-WL-08'),
    ('woodgrain-laminate', '1mm', 'XP-WL-10'),
    ('textured-laminate', '1mm', 'XP-TL-10'),
    ('solid-core-door', '30x78', 'XP-SCD-3078'),
    ('solid-core-door', '32x78', 'XP-SCD-3278'),
    ('solid-core-door', '36x78', 'XP-SCD-3678'),
    ('hollow-core-door', '30x78', 'XP-HCD-3078'),
    ('hollow-core-door', '32x78', 'XP-HCD-3278'),
    ('cabinet-hardware', 'Stainless', 'XP-CH-SS'),
    ('cabinet-hardware', 'Zinc Alloy', 'XP-CH-ZA'),
    ('structural-fixings', 'Various', 'XP-SF-VAR'),
    ('mdf-18mm', '6mm', 'XP-MDF-6'),
    ('mdf-18mm', '9mm', 'XP-MDF-9'),
    ('mdf-18mm', '12mm', 'XP-MDF-12'),
    ('mdf-18mm', '18mm', 'XP-MDF-18')
)
insert into public.product_variants (product_id, label, sku)
select
  p.id,
  v.label,
  v.sku
from variants_data v
join public.products p on p.slug = v.product_slug
on conflict (sku) do update
set
  product_id = excluded.product_id,
  label = excluded.label;

-- Rewards -----------------------------------------------------------------
with rewards_data(name, description, points_cost, tier_required, stock_qty) as (
  values
    ('5% Discount', 'Use your points for a 5% discount on the next eligible purchase.', 250, 'bronze', null),
    ('10% Discount', 'Unlock a stronger discount once you build up your wallet.', 500, 'silver', null),
    ('Free Delivery', 'Free local delivery on an eligible order.', 350, 'bronze', 50),
    ('Free Laminate Sheet', 'Redeem for one laminate sheet from the standard catalogue range.', 900, 'gold', 20),
    ('15% Discount', 'Premium discount reward for loyal customers.', 1200, 'gold', null),
    ('Rs 500 Cash Reward', 'Flat Rs 500 benefit applied to a qualifying invoice.', 1500, 'gold', 30),
    ('Priority Service', 'Fast-track handling for upcoming orders and enquiries.', 1800, 'platinum', 25),
    ('VIP Bulk Pricing', 'Unlock preferred pricing for qualifying bulk purchases.', 2500, 'platinum', 10)
),
deleted as (
  delete from public.rewards
  where name in (select name from rewards_data)
  returning name
)
insert into public.rewards (name, description, points_cost, tier_required, is_active, stock_qty)
select
  name,
  description,
  points_cost,
  tier_required,
  true,
  stock_qty
from rewards_data
;

-- Optional test QR codes --------------------------------------------------
-- Replace these with your real printed codes before production use.
with qr_seed(code, product_slug, variant_sku, points_value) as (
  values
    ('XP-DEMO-BWR18-0001', 'bwr-plywood', 'XP-BWR-18', 40),
    ('XP-DEMO-BWP18-0001', 'bwp-plywood', 'XP-BWP-18', 55),
    ('XP-DEMO-MAR18-0001', 'marine-plywood', 'XP-MAR-18', 70),
    ('XP-DEMO-BB19-0001', 'block-board-19mm', 'XP-BB19-19', 50),
    ('XP-DEMO-ML10-0001', 'matte-laminate', 'XP-ML-10', 20),
    ('XP-DEMO-MDF18-0001', 'mdf-18mm', 'XP-MDF-18', 35)
)
insert into public.qr_codes (code, product_id, product_variant_id, points_value, status)
select
  q.code,
  p.id,
  v.id,
  q.points_value,
  'active'
from qr_seed q
join public.products p on p.slug = q.product_slug
join public.product_variants v on v.sku = q.variant_sku
on conflict (code) do update
set
  product_id = excluded.product_id,
  product_variant_id = excluded.product_variant_id,
  points_value = excluded.points_value,
  status = 'active';

commit;
