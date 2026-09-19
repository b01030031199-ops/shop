-- =====================================================
-- Maison Bori 상품 목록을 Supabase 에 올리는 SQL
--
-- 사용법: Supabase 대시보드 > SQL Editor > New query 에
--         이 파일 내용을 전부 붙여 넣고 [Run] 을 누르세요.
-- 여러 번 실행해도 상품이 중복되지 않고 최신 내용으로 덮어써집니다.
-- =====================================================

-- 1) 상품 테이블 만들기 (이미 있으면 그대로 둠)
create table if not exists public.products (
  id          int primary key,                 -- 상품 번호 (홈페이지 순서)
  name        text not null,                   -- 상품명
  category    text not null,                   -- 간식 / 장난감 / 산책 / 용품 / 위생
  price       int  not null,                   -- 판매가 (할인된 가격)
  list_price  int  not null,                   -- 정가
  image_url   text not null,                   -- 상품 사진 주소
  created_at  timestamptz not null default now()
);

-- 1-1) 할인율 칸 - 직접 적지 않고 정가·판매가로 자동 계산
--      (가격만 고치면 할인율이 저절로 바뀜, 반올림한 % 정수)
--      예전 버전처럼 숫자를 직접 적던 칸이 있으면 지우고 계산 칸으로 바꿈
do $$
begin
  if exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'products'
      and column_name = 'discount' and is_generated = 'NEVER'
  ) then
    alter table public.products drop column discount;
  end if;
end $$;

alter table public.products
  add column if not exists discount int generated always as (
    case
      when list_price > 0 and list_price > price
        then round((list_price - price) * 100.0 / list_price)::int
      else 0
    end
  ) stored;

-- 2) 보안 설정 (RLS) - 누구나 '보기'만 가능, 추가·수정·삭제는 대시보드에서만
alter table public.products enable row level security;

drop policy if exists "상품은 누구나 볼 수 있음" on public.products;
create policy "상품은 누구나 볼 수 있음"
  on public.products for select
  to anon, authenticated
  using (true);

grant select on public.products to anon, authenticated;

-- 3) 홈페이지 상품 15개 넣기 (할인율은 자동 계산이라 넣지 않음)
insert into public.products (id, name, category, price, list_price, image_url) values
  ( 1, '오래오래 껌 간식', '간식',  12000, 18000, 'https://b01030031199-ops.github.io/shop/img/p1-chew.jpg'),
  ( 2, '푹신한 삑삑이 인형', '장난감',  11000, 22000, 'https://b01030031199-ops.github.io/shop/img/p2-toy.jpg'),
  ( 3, '편안한 가슴줄 세트', '산책',  17500, 35000, 'https://b01030031199-ops.github.io/shop/img/p3-harness.jpg'),
  ( 4, '강아지 케이지', '용품',  70000, 140000, 'https://b01030031199-ops.github.io/shop/img/p4-crate.jpg'),
  ( 5, '폭신 강아지 방석', '용품',  20000, 40000, 'https://b01030031199-ops.github.io/shop/img/p5-bed.jpg'),
  ( 6, '연어 트릿 (100g)', '간식',   8000, 16000, 'https://b01030031199-ops.github.io/shop/img/p6-treat.jpg'),
  ( 7, '튼튼 노즈워크 공', '장난감',   9500, 19000, 'https://b01030031199-ops.github.io/shop/img/p7-ball.jpg'),
  ( 8, '실리콘 칫솔 세트', '위생',   6000, 12000, 'https://b01030031199-ops.github.io/shop/img/p8-brush.jpg'),
  ( 9, '저자극 강아지 샴푸', '위생',  12500, 25000, 'https://b01030031199-ops.github.io/shop/img/p9-shampoo.jpg'),
  (10, '겨울 포근 패딩 옷', '용품',  21000, 42000, 'https://b01030031199-ops.github.io/shop/img/p10-coat.jpg'),
  (11, '천천히 먹는 슬로우 식기', '용품',  12000, 24000, 'https://b01030031199-ops.github.io/shop/img/p11-bowl.jpg'),
  (12, '수제 가죽 목줄', '산책',  24000, 48000, 'https://b01030031199-ops.github.io/shop/img/p12-collar.jpg'),
  (13, '면 로프 터그 장난감', '장난감',   7000, 14000, 'https://b01030031199-ops.github.io/shop/img/p13-rope.jpg'),
  (14, '수제 뼈다귀 쿠키', '간식',   6500, 13000, 'https://b01030031199-ops.github.io/shop/img/p14-treat.jpg'),
  (15, '후드 레인코트', '용품',  18000, 36000, 'https://b01030031199-ops.github.io/shop/img/p15-raincoat.jpg')
on conflict (id) do update set
  name       = excluded.name,
  category   = excluded.category,
  price      = excluded.price,
  list_price = excluded.list_price,
  image_url  = excluded.image_url;

-- 4) 확인 - 아래에 15개 상품이 보이면 성공
select id, name, category, price, list_price, discount from public.products order by id;
