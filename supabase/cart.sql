-- =====================================================
-- Maison Bori 회원 장바구니 테이블
--
-- 사용법: Supabase 대시보드 > SQL Editor 에 전부 붙여 넣고 [Run]
-- 여러 번 실행해도 안전합니다. (products.sql 을 먼저 실행해야 함)
-- =====================================================

-- 1) 장바구니 테이블 - 회원 한 명 + 상품 하나 = 한 줄
create table if not exists public.cart_items (
  user_id     uuid not null default auth.uid()
              references auth.users (id) on delete cascade,      -- 회원 (탈퇴하면 장바구니도 삭제)
  product_id  int  not null
              references public.products (id) on delete cascade, -- 상품 (상품이 없어지면 같이 삭제)
  qty         int  not null default 1 check (qty > 0),           -- 수량
  created_at  timestamptz not null default now(),                -- 처음 담은 시각 (목록 순서)
  primary key (user_id, product_id)
);

-- 2) 보안 설정 (RLS) - 로그인한 회원은 '자기 장바구니'만 보고 고칠 수 있음
alter table public.cart_items enable row level security;

drop policy if exists "내 장바구니 보기" on public.cart_items;
create policy "내 장바구니 보기"
  on public.cart_items for select
  to authenticated
  using ((select auth.uid()) = user_id);

drop policy if exists "내 장바구니에 담기" on public.cart_items;
create policy "내 장바구니에 담기"
  on public.cart_items for insert
  to authenticated
  with check ((select auth.uid()) = user_id);

drop policy if exists "내 장바구니 수량 바꾸기" on public.cart_items;
create policy "내 장바구니 수량 바꾸기"
  on public.cart_items for update
  to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

drop policy if exists "내 장바구니에서 빼기" on public.cart_items;
create policy "내 장바구니에서 빼기"
  on public.cart_items for delete
  to authenticated
  using ((select auth.uid()) = user_id);

-- 로그인한 회원에게만 권한을 줌 (로그인 안 한 방문자는 접근 불가)
revoke all on public.cart_items from anon;
grant select, insert, update, delete on public.cart_items to authenticated;

-- 3) 확인
select policyname, cmd from pg_policies
where schemaname = 'public' and tablename = 'cart_items'
order by policyname;
