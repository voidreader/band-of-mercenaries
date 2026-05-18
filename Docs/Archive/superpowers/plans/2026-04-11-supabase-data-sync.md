# Supabase 정적 데이터 동기화 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 번들 JSON 기반 정적 데이터 로딩을 Supabase 서버 기반으로 전환하고, 버전 기반 델타 싱크를 구현한다.

**Architecture:** Flutter 앱 시작 시 Supabase `data_versions` 테이블과 로컬 버전을 비교하여 변경된 테이블만 다운로드한다. 다운로드된 데이터는 로컬 JSON 캐시로 저장되며, 기존 freezed 모델의 `fromJson()`을 재사용한다. operation-bom 웹앱에서 관리자가 수동으로 버전을 발행하면 클라이언트가 다음 앱 시작/포그라운드 복귀 시 감지하여 갱신한다.

**Tech Stack:** supabase_flutter, flutter_dotenv, Hive (settings), Next.js (operation-bom)

**Spec:** `docs/superpowers/specs/2026-04-11-supabase-data-sync-design.md`

---

## 프로젝트 구조

### 변경되는 프로젝트 2개

1. **operation-bom** (`/Users/radiogaga/git/operation-bom/`) — Supabase 마이그레이션 + 버전 발행 UI
2. **band-of-mercenaries** (`/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/`) — Flutter 앱

### Flutter 앱 — 파일 변경 요약

**새로 생성:**
- `lib/core/data/supabase_initializer.dart` — Supabase + dotenv 초기화
- `lib/core/data/data_loader.dart` — 캐시 파일 I/O + Supabase 응답 → 모델 변환
- `lib/core/data/sync_service.dart` — 버전 비교 + 델타 다운로드 + 캐시 관리
- `.env.example` — Supabase 연결 정보 템플릿
- `test/core/data/data_loader_test.dart` — DataLoader 단위 테스트

**수정:**
- `pubspec.yaml` — 패키지 추가, assets/json 제거
- `.gitignore` — .env 추가
- `lib/core/models/*.dart` (11개) — @JsonKey PascalCase → snake_case
- `lib/core/providers/static_data_provider.dart` — DataLoader 기반으로 전환
- `lib/main.dart` — Supabase 초기화 + SyncService 호출
- `lib/app.dart` — 포그라운드 복귀 시 싱크 트리거

**삭제:**
- `lib/core/data/json_loader.dart`
- `assets/json/*.json` (11개)
- `test/core/data/json_loader_test.dart`

### operation-bom — 파일 변경 요약

**새로 생성:**
- `supabase/migrations/002_data_versions.sql` — data_versions 테이블 + RLS
- `src/components/publish-version-button.tsx` — 버전 발행 버튼

**수정:**
- `src/app/(authenticated)/data/[table]/page.tsx` — 버전 표시 + 발행 버튼 연동

---

## Task 1: Supabase 마이그레이션 — data_versions 테이블 + anon RLS

**Files:**
- Create: `/Users/radiogaga/git/operation-bom/supabase/migrations/002_data_versions.sql`

- [ ] **Step 1: 마이그레이션 SQL 파일 작성**

```sql
-- ============================================
-- Data Versions (for client sync)
-- ============================================
CREATE TABLE data_versions (
  table_name TEXT PRIMARY KEY,
  version    INT NOT NULL DEFAULT 1,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Initial rows for all 11 game data tables
INSERT INTO data_versions (table_name) VALUES
  ('jobs'),
  ('regions'),
  ('traits'),
  ('difficulties'),
  ('quest_types'),
  ('quest_pools'),
  ('person_names'),
  ('travel_events'),
  ('facilities'),
  ('ranks'),
  ('mercenary_wages');

-- RLS
ALTER TABLE data_versions ENABLE ROW LEVEL SECURITY;

-- Anyone (including anon) can read versions
CREATE POLICY "Anyone can view data_versions"
  ON data_versions FOR SELECT
  TO anon, authenticated
  USING (true);

-- Only editor/admin can update versions
CREATE POLICY "Editors can update data_versions"
  ON data_versions FOR UPDATE
  TO authenticated
  USING (public.get_user_role() IN ('admin', 'editor'));

-- ============================================
-- Add anon SELECT policies to all game data tables
-- (existing policies only allow 'authenticated')
-- ============================================
DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOR tbl IN SELECT unnest(ARRAY[
    'regions', 'quest_pools', 'quest_types', 'travel_events',
    'jobs', 'traits', 'person_names', 'difficulties',
    'ranks', 'mercenary_wages', 'facilities'
  ]) LOOP
    EXECUTE format(
      'CREATE POLICY "Anon can view %1$s" ON %1$I FOR SELECT TO anon USING (true)',
      tbl
    );
  END LOOP;
END $$;
```

- [ ] **Step 2: Supabase 대시보드에서 마이그레이션 적용**

Run: Supabase 대시보드 SQL Editor에서 위 SQL 실행, 또는 `supabase db push` (CLI 사용 시)

Expected: `data_versions` 테이블 생성, 11개 행 존재, anon SELECT 정책 적용

- [ ] **Step 3: 커밋**

```bash
cd /Users/radiogaga/git/operation-bom
git add supabase/migrations/002_data_versions.sql
git commit -m "feat: add data_versions table and anon SELECT policies for client sync"
```

---

## Task 2: operation-bom — 버전 발행 버튼

**Files:**
- Create: `/Users/radiogaga/git/operation-bom/src/components/publish-version-button.tsx`
- Modify: `/Users/radiogaga/git/operation-bom/src/app/(authenticated)/data/[table]/page.tsx`

- [ ] **Step 1: PublishVersionButton 컴포넌트 작성**

```tsx
// src/components/publish-version-button.tsx
"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { toast } from "sonner";

interface PublishVersionButtonProps {
  supabaseTable: string;
  displayName: string;
  currentVersion: number;
  userId: string;
}

export function PublishVersionButton({
  supabaseTable,
  displayName,
  currentVersion,
  userId,
}: PublishVersionButtonProps) {
  const [open, setOpen] = useState(false);
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  async function handlePublish() {
    setLoading(true);

    const newVersion = currentVersion + 1;

    const { error } = await supabase
      .from("data_versions")
      .update({ version: newVersion, updated_at: new Date().toISOString() })
      .eq("table_name", supabaseTable);

    if (error) {
      toast.error(error.message);
      setLoading(false);
      return;
    }

    await supabase.from("change_logs").insert({
      table_name: "data_versions",
      record_id: supabaseTable,
      action: "update",
      user_id: userId,
      summary: `버전 발행: ${displayName} v${newVersion}`,
    });

    toast.success(`${displayName} v${newVersion} 발행 완료`);
    setOpen(false);
    router.refresh();
  }

  return (
    <div className="flex items-center gap-3">
      <span className="text-sm text-muted-foreground">v{currentVersion}</span>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogTrigger asChild>
          <Button variant="outline" size="sm">
            버전 발행
          </Button>
        </DialogTrigger>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>버전 발행</DialogTitle>
            <DialogDescription>
              {displayName}의 변경사항을 클라이언트에 배포하시겠습니까?
              (v{currentVersion} → v{currentVersion + 1})
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setOpen(false)}>
              취소
            </Button>
            <Button onClick={handlePublish} disabled={loading}>
              {loading ? "발행 중..." : "발행"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
```

- [ ] **Step 2: page.tsx에 버전 정보 + 발행 버튼 연동**

`/Users/radiogaga/git/operation-bom/src/app/(authenticated)/data/[table]/page.tsx` 수정:

```tsx
import { notFound } from "next/navigation";
import Link from "next/link";
import { createClient } from "@/lib/supabase/server";
import { getTableConfig } from "@/lib/table-config";
import { Button } from "@/components/ui/button";
import { PublishVersionButton } from "@/components/publish-version-button";
import { TableClient } from "./table-client";

export default async function TableListPage({
  params,
}: {
  params: Promise<{ table: string }>;
}) {
  const { table: tableSlug } = await params;
  const config = getTableConfig(tableSlug);

  if (!config) {
    notFound();
  }

  const supabase = await createClient();

  const { data: { user } } = await supabase.auth.getUser();
  const { data: profile } = await supabase
    .from("profiles")
    .select("id, role")
    .eq("id", user!.id)
    .single();

  const canEdit = profile?.role === "admin" || profile?.role === "editor";

  const { data, error } = await supabase
    .from(config.supabaseTable)
    .select("*")
    .order(config.primaryKey, { ascending: true });

  if (error) {
    throw new Error(`Failed to load ${config.displayName}: ${error.message}`);
  }

  // Fetch current version
  const { data: versionData } = await supabase
    .from("data_versions")
    .select("version")
    .eq("table_name", config.supabaseTable)
    .single();

  const currentVersion = versionData?.version ?? 0;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <div className="flex items-center gap-4">
          <h1 className="text-2xl font-bold">{config.displayName}</h1>
          {canEdit && (
            <PublishVersionButton
              supabaseTable={config.supabaseTable}
              displayName={config.displayName}
              currentVersion={currentVersion}
              userId={profile!.id}
            />
          )}
        </div>
        {canEdit && (
          <Link href={`/data/${tableSlug}/new`}>
            <Button>+ 추가</Button>
          </Link>
        )}
      </div>
      <TableClient
        config={config}
        tableSlug={tableSlug}
        data={(data as Record<string, unknown>[]) ?? []}
        canEdit={canEdit}
        userId={profile!.id}
      />
    </div>
  );
}
```

- [ ] **Step 3: 동작 확인**

Run: operation-bom 개발 서버에서 데이터 페이지 접근
Expected: 테이블 제목 옆에 `v1`과 "버전 발행" 버튼 표시. 클릭 시 확인 다이얼로그 → v2로 업데이트

- [ ] **Step 4: 커밋**

```bash
cd /Users/radiogaga/git/operation-bom
git add src/components/publish-version-button.tsx src/app/\(authenticated\)/data/\[table\]/page.tsx
git commit -m "feat: add version publish button to data table pages"
```

---

## Task 3: Flutter — 패키지 추가 + .env 설정

**Files:**
- Modify: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/pubspec.yaml`
- Modify: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/.gitignore`
- Create: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/.env.example`
- Create: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/.env`

- [ ] **Step 1: pubspec.yaml에 패키지 추가 + assets 변경**

`pubspec.yaml` dependencies 섹션에 추가:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  hive_flutter: ^1.1.0
  hive: ^2.2.3
  freezed_annotation: ^2.4.4
  json_annotation: ^4.9.0
  uuid: ^4.4.2
  supabase_flutter: ^2.8.4
  flutter_dotenv: ^5.2.1
  path_provider: ^2.1.5
```

flutter 섹션의 assets 변경:

```yaml
flutter:
  uses-material-design: true
  assets:
    - .env
```

- [ ] **Step 2: .env.example 및 .env 생성**

`.env.example`:
```
SUPABASE_URL=your-supabase-url
SUPABASE_ANON_KEY=your-supabase-anon-key
```

`.env` (실제 값 — 사용자가 직접 입력):
```
SUPABASE_URL=your-actual-supabase-url
SUPABASE_ANON_KEY=your-actual-supabase-anon-key
```

- [ ] **Step 3: .gitignore에 .env 추가**

`.gitignore` 파일 맨 끝에 추가:

```
# Environment variables
.env
```

- [ ] **Step 4: 패키지 설치**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && flutter pub get`
Expected: 의존성 해결 성공

- [ ] **Step 5: 커밋**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
git add band_of_mercenaries/pubspec.yaml band_of_mercenaries/pubspec.lock band_of_mercenaries/.gitignore band_of_mercenaries/.env.example
git commit -m "feat: add supabase_flutter, flutter_dotenv, path_provider packages"
```

---

## Task 4: Flutter — 모든 정적 데이터 모델 @JsonKey를 snake_case로 변경

**Files:**
- Modify: `lib/core/models/difficulty.dart`
- Modify: `lib/core/models/job.dart`
- Modify: `lib/core/models/trait_data.dart`
- Modify: `lib/core/models/region.dart`
- Modify: `lib/core/models/quest_type.dart`
- Modify: `lib/core/models/quest_pool.dart`
- Modify: `lib/core/models/person_name.dart`
- Modify: `lib/core/models/travel_event.dart`
- Modify: `lib/core/models/facility.dart`
- Modify: `lib/core/models/rank.dart`
- Modify: `lib/core/models/mercenary_wage.dart`

모든 모델에서 @JsonKey의 `name` 값을 Supabase 컬럼명(snake_case)으로 변경한다.
Dart 필드명과 Supabase 컬럼명이 동일한 경우 @JsonKey를 제거한다.

- [ ] **Step 1: difficulty.dart 수정**

```dart
@freezed
class Difficulty with _$Difficulty {
  const factory Difficulty({
    required int level,
    @JsonKey(name: 'enemy_power') required int enemyPower,
    @JsonKey(name: 'reward_multiplier') required double rewardMultiplier,
    @JsonKey(name: 'success_penalty') required double successPenalty,
    @JsonKey(name: 'injury_rate') required double injuryRate,
    @JsonKey(name: 'death_rate') required double deathRate,
    @JsonKey(name: 'min_dispatch_cost') required int minDispatchCost,
    @JsonKey(name: 'max_dispatch_cost') required int maxDispatchCost,
  }) = _Difficulty;

  factory Difficulty.fromJson(Map<String, dynamic> json) =>
      _$DifficultyFromJson(json);
}
```

DifficultyList 클래스는 그대로 둔다 (사용되지 않지만 삭제 범위를 최소화).

- [ ] **Step 2: job.dart 수정**

```dart
@freezed
class Job with _$Job {
  const factory Job({
    required String id,
    required int tier,
    required String name,
    @JsonKey(name: 'base_atk') required int baseAtk,
    @JsonKey(name: 'base_def') required int baseDef,
    @JsonKey(name: 'base_hp') required int baseHp,
    required double speed,
  }) = _Job;

  factory Job.fromJson(Map<String, dynamic> json) => _$JobFromJson(json);
}
```

- [ ] **Step 3: trait_data.dart 수정**

```dart
@freezed
class TraitData with _$TraitData {
  const factory TraitData({
    required String id,
    required String name,
    @JsonKey(name: 'effect_type') required String effectType,
    required double value,
  }) = _TraitData;

  factory TraitData.fromJson(Map<String, dynamic> json) =>
      _$TraitDataFromJson(json);
}
```

- [ ] **Step 4: region.dart 수정**

주의: `Desc` → `description` (Supabase 컬럼명과 일치시킴)

```dart
@freezed
class Region with _$Region {
  const factory Region({
    required int continent,
    required int region,
    @JsonKey(name: 'region_name') required String regionName,
    @JsonKey(name: 'region_tier') required int regionTier,
    @JsonKey(name: 'recommend_power') required int recommendPower,
    required String description,
  }) = _Region;

  factory Region.fromJson(Map<String, dynamic> json) =>
      _$RegionFromJson(json);
}
```

> **주의:** 필드명이 `desc` → `description`으로 변경되므로, 코드베이스 전체에서 `.desc` 참조를 `.description`으로 변경해야 한다. `grep -r '\.desc' lib/`로 사용처를 찾아 수정한다.

- [ ] **Step 5: quest_type.dart 수정**

```dart
@freezed
class QuestType with _$QuestType {
  const factory QuestType({
    required String id,
    required String name,
    @JsonKey(name: 'base_reward') required int baseReward,
    @JsonKey(name: 'base_duration') required int baseDuration,
    @JsonKey(name: 'risk_factor') required double riskFactor,
  }) = _QuestType;

  factory QuestType.fromJson(Map<String, dynamic> json) =>
      _$QuestTypeFromJson(json);
}
```

- [ ] **Step 6: quest_pool.dart 수정**

```dart
@freezed
class QuestPool with _$QuestPool {
  const factory QuestPool({
    required String id,
    required String name,
    required double type,
    required double difficulty,
    @JsonKey(name: 'min_region_diff') required double minRegionDiff,
    @JsonKey(name: 'max_region_diff') required double maxRegionDiff,
  }) = _QuestPool;

  factory QuestPool.fromJson(Map<String, dynamic> json) =>
      _$QuestPoolFromJson(json);
}
```

- [ ] **Step 7: person_name.dart 수정**

```dart
@freezed
class PersonName with _$PersonName {
  const factory PersonName({
    required int id,
    required String korean,
  }) = _PersonName;

  factory PersonName.fromJson(Map<String, dynamic> json) =>
      _$PersonNameFromJson(json);
}
```

- [ ] **Step 8: travel_event.dart 수정**

```dart
@freezed
class TravelEvent with _$TravelEvent {
  const factory TravelEvent({
    required String id,
    required String name,
    required String type,
    @JsonKey(name: 'effect_type') required String effectType,
    required double magnitude,
    @JsonKey(name: 'min_tier') required int minTier,
    @JsonKey(name: 'max_tier') required int maxTier,
    required String description,
  }) = _TravelEvent;

  factory TravelEvent.fromJson(Map<String, dynamic> json) =>
      _$TravelEventFromJson(json);
}
```

- [ ] **Step 9: facility.dart 수정**

```dart
@freezed
class Facility with _$Facility {
  const factory Facility({
    required String id,
    required String name,
    @JsonKey(name: 'effect_type') required String effectType,
    @JsonKey(name: 'max_level') required int maxLevel,
    required List<int> costs,
    required List<double> values,
  }) = _Facility;

  factory Facility.fromJson(Map<String, dynamic> json) =>
      _$FacilityFromJson(json);
}
```

- [ ] **Step 10: rank.dart 수정**

```dart
@freezed
class Rank with _$Rank {
  const factory Rank({
    required String grade,
    required String name,
    @JsonKey(name: 'required_reputation') required int requiredReputation,
    @JsonKey(name: 'unlock_tier') required int unlockTier,
  }) = _Rank;

  factory Rank.fromJson(Map<String, dynamic> json) =>
      _$RankFromJson(json);
}
```

- [ ] **Step 11: mercenary_wage.dart 수정**

```dart
@freezed
class MercenaryWage with _$MercenaryWage {
  const factory MercenaryWage({
    required int tier,
    required int wage,
  }) = _MercenaryWage;

  factory MercenaryWage.fromJson(Map<String, dynamic> json) =>
      _$MercenaryWageFromJson(json);
}
```

- [ ] **Step 12: Region.desc → Region.description 참조 수정**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && grep -rn '\.desc' lib/ --include='*.dart' | grep -v '.g.dart' | grep -v '.freezed.dart'`

나오는 모든 `.desc` 참조를 `.description`으로 변경한다. (region 모델의 필드명 변경에 따른 것)

- [ ] **Step 13: 커밋**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
git add band_of_mercenaries/lib/core/models/
git commit -m "refactor: update model @JsonKey annotations to snake_case for Supabase compatibility"
```

---

## Task 5: Flutter — build_runner로 코드 재생성

**Files:**
- Regenerate: `lib/core/models/*.g.dart`, `lib/core/models/*.freezed.dart`

- [ ] **Step 1: build_runner 실행**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && dart run build_runner build --delete-conflicting-outputs`
Expected: 모든 `.g.dart`, `.freezed.dart` 파일 재생성 성공

- [ ] **Step 2: 정적 분석 확인**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && flutter analyze`
Expected: 에러 없음 (Region.desc → Region.description 참조 변경이 누락되었다면 여기서 발견됨)

- [ ] **Step 3: 커밋**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
git add band_of_mercenaries/lib/core/models/
git commit -m "build: regenerate freezed and json_serializable code for snake_case keys"
```

---

## Task 6: Flutter — SupabaseInitializer

**Files:**
- Create: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/lib/core/data/supabase_initializer.dart`

- [ ] **Step 1: SupabaseInitializer 작성**

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseInitializer {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');

    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
```

- [ ] **Step 2: 커밋**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
git add band_of_mercenaries/lib/core/data/supabase_initializer.dart
git commit -m "feat: add SupabaseInitializer with dotenv config"
```

---

## Task 7: Flutter — DataLoader + 테스트

**Files:**
- Create: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/lib/core/data/data_loader.dart`
- Create: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/test/core/data/data_loader_test.dart`

- [ ] **Step 1: DataLoader 테스트 작성**

```dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';

void main() {
  late Directory tempDir;
  late DataLoader dataLoader;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('data_loader_test_');
    dataLoader = DataLoader(cacheDir: tempDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('DataLoader', () {
    test('hasCache returns false when no cache files exist', () {
      expect(dataLoader.hasCache(), false);
    });

    test('saveToCache writes JSON file', () async {
      final data = [
        {'id': 'farmer', 'tier': 1, 'name': '농부', 'base_atk': 4, 'base_def': 3, 'base_hp': 24, 'speed': 0.96},
      ];

      await dataLoader.saveToCache('jobs', data);

      final file = File('${tempDir.path}/jobs.json');
      expect(file.existsSync(), true);

      final content = jsonDecode(file.readAsStringSync()) as List;
      expect(content.length, 1);
      expect(content[0]['id'], 'farmer');
    });

    test('hasCache returns true after saving', () async {
      await dataLoader.saveToCache('jobs', [{'id': 'test'}]);
      expect(dataLoader.hasCache(), true);
    });

    test('loadFromCache parses saved data correctly', () async {
      final data = [
        {'id': 'farmer', 'tier': 1, 'name': '농부', 'base_atk': 4, 'base_def': 3, 'base_hp': 24, 'speed': 0.96},
      ];

      await dataLoader.saveToCache('jobs', data);
      final jobs = dataLoader.loadFromCache('jobs', Job.fromJson);

      expect(jobs.length, 1);
      expect(jobs[0].id, 'farmer');
      expect(jobs[0].tier, 1);
      expect(jobs[0].baseAtk, 4);
    });

    test('loadFromCache returns empty list when no cache', () {
      final result = dataLoader.loadFromCache('jobs', Job.fromJson);
      expect(result, isEmpty);
    });

    test('parseSupabaseResponse converts list of maps to models', () {
      final response = [
        {'grade': 'F', 'name': '무명', 'required_reputation': 0, 'unlock_tier': 1},
        {'grade': 'E', 'name': '신입', 'required_reputation': 100, 'unlock_tier': 2},
      ];

      final ranks = DataLoader.parseList(response, Rank.fromJson);
      expect(ranks.length, 2);
      expect(ranks[0].grade, 'F');
      expect(ranks[1].requiredReputation, 100);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && flutter test test/core/data/data_loader_test.dart`
Expected: FAIL — `DataLoader` 클래스가 아직 없음

- [ ] **Step 3: DataLoader 구현**

```dart
import 'dart:convert';
import 'dart:io';

class DataLoader {
  final Directory cacheDir;

  DataLoader({required this.cacheDir});

  /// 캐시 파일이 하나라도 존재하는지 확인 (첫 실행 판별)
  bool hasCache() {
    if (!cacheDir.existsSync()) return false;
    return cacheDir.listSync().whereType<File>().any((f) => f.path.endsWith('.json'));
  }

  /// 특정 테이블의 캐시 파일 존재 여부
  bool hasCacheFor(String tableName) {
    final file = File('${cacheDir.path}/$tableName.json');
    return file.existsSync();
  }

  /// Supabase 응답을 캐시 파일로 저장
  Future<void> saveToCache(String tableName, List<Map<String, dynamic>> data) async {
    if (!cacheDir.existsSync()) {
      cacheDir.createSync(recursive: true);
    }
    final file = File('${cacheDir.path}/$tableName.json');
    await file.writeAsString(jsonEncode(data));
  }

  /// 캐시 파일에서 모델 리스트 로딩
  List<T> loadFromCache<T>(String tableName, T Function(Map<String, dynamic>) fromJson) {
    final file = File('${cacheDir.path}/$tableName.json');
    if (!file.existsSync()) return [];

    final jsonString = file.readAsStringSync();
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Supabase 응답(List<Map>)을 모델 리스트로 변환
  static List<T> parseList<T>(
    List<Map<String, dynamic>> data,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    return data.map((e) => fromJson(e)).toList();
  }
}
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && flutter test test/core/data/data_loader_test.dart`
Expected: All tests PASS

- [ ] **Step 5: 커밋**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
git add band_of_mercenaries/lib/core/data/data_loader.dart band_of_mercenaries/test/core/data/data_loader_test.dart
git commit -m "feat: add DataLoader for cache file I/O and Supabase response parsing"
```

---

## Task 8: Flutter — SyncService

**Files:**
- Create: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/lib/core/data/sync_service.dart`

- [ ] **Step 1: SyncService 구현**

```dart
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';

enum SyncStatus {
  fullDownload,  // 첫 실행: 전체 다운로드
  updated,       // 변경된 테이블 갱신됨
  noChanges,     // 변경 없음
  offline,       // 서버 연결 실패, 캐시 사용
}

class SyncService {
  final SupabaseClient _client;
  final DataLoader _dataLoader;

  static const String _versionsKey = 'dataVersions';

  static const List<String> allTables = [
    'jobs',
    'regions',
    'traits',
    'difficulties',
    'quest_types',
    'quest_pools',
    'person_names',
    'travel_events',
    'facilities',
    'ranks',
    'mercenary_wages',
  ];

  SyncService({
    required SupabaseClient client,
    required DataLoader dataLoader,
  })  : _client = client,
        _dataLoader = dataLoader;

  Box get _settingsBox => Hive.box(HiveInitializer.settingsBoxName);

  /// 메인 싱크 로직
  Future<SyncStatus> sync() async {
    final hasCache = _dataLoader.hasCache();

    if (!hasCache) {
      // 첫 실행: 전체 다운로드 필수 (실패 시 예외)
      await _fullDownload();
      return SyncStatus.fullDownload;
    }

    // 재실행: 서버 연결 시도
    try {
      final serverVersions = await _fetchServerVersions();
      final localVersions = _getLocalVersions();
      final changedTables = _findChangedTables(serverVersions, localVersions);

      if (changedTables.isEmpty) {
        return SyncStatus.noChanges;
      }

      await _downloadTables(changedTables);
      _saveLocalVersions(serverVersions);
      return SyncStatus.updated;
    } catch (e) {
      // 서버 연결 실패 — 캐시 사용
      return SyncStatus.offline;
    }
  }

  /// 서버에서 data_versions 테이블 조회
  Future<Map<String, int>> _fetchServerVersions() async {
    final response = await _client
        .from('data_versions')
        .select('table_name, version');

    final versions = <String, int>{};
    for (final row in response as List) {
      versions[row['table_name'] as String] = row['version'] as int;
    }
    return versions;
  }

  /// 로컬 저장된 버전 정보
  Map<String, int> _getLocalVersions() {
    final raw = _settingsBox.get(_versionsKey);
    if (raw == null) return {};
    return Map<String, int>.from(raw as Map);
  }

  /// 로컬 버전 저장
  void _saveLocalVersions(Map<String, int> versions) {
    _settingsBox.put(_versionsKey, versions);
  }

  /// 서버와 로컬 버전 비교 → 변경된 테이블 목록
  List<String> _findChangedTables(
    Map<String, int> serverVersions,
    Map<String, int> localVersions,
  ) {
    final changed = <String>[];
    for (final entry in serverVersions.entries) {
      final localVersion = localVersions[entry.key] ?? 0;
      if (entry.value != localVersion) {
        changed.add(entry.key);
      }
    }
    return changed;
  }

  /// 전체 테이블 다운로드 (첫 실행)
  Future<void> _fullDownload() async {
    await _downloadTables(allTables);
    final serverVersions = await _fetchServerVersions();
    _saveLocalVersions(serverVersions);
  }

  /// 지정된 테이블들 다운로드 + 캐시 저장
  Future<void> _downloadTables(List<String> tableNames) async {
    await Future.wait(
      tableNames.map((table) => _downloadTable(table)),
    );
  }

  /// 단일 테이블 다운로드 + 캐시 저장
  Future<void> _downloadTable(String tableName) async {
    final response = await _client.from(tableName).select();
    final data = (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    await _dataLoader.saveToCache(tableName, data);
  }
}
```

- [ ] **Step 2: 커밋**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
git add band_of_mercenaries/lib/core/data/sync_service.dart
git commit -m "feat: add SyncService for version-based delta sync with Supabase"
```

---

## Task 9: Flutter — staticDataProvider + main.dart + app.dart 통합

**Files:**
- Modify: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/lib/core/providers/static_data_provider.dart`
- Modify: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/lib/main.dart`
- Modify: `/Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries/lib/app.dart`

- [ ] **Step 1: static_data_provider.dart 수정**

기존 `rootBundle` + `JsonLoader` 기반을 `DataLoader` 캐시 파일 기반으로 전환:

```dart
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/models/difficulty.dart';
import 'package:band_of_mercenaries/core/models/job.dart';
import 'package:band_of_mercenaries/core/models/trait_data.dart';
import 'package:band_of_mercenaries/core/models/region.dart';
import 'package:band_of_mercenaries/core/models/quest_type.dart';
import 'package:band_of_mercenaries/core/models/quest_pool.dart';
import 'package:band_of_mercenaries/core/models/person_name.dart';
import 'package:band_of_mercenaries/core/models/travel_event.dart';
import 'package:band_of_mercenaries/core/models/facility.dart';
import 'package:band_of_mercenaries/core/models/rank.dart';
import 'package:band_of_mercenaries/core/models/mercenary_wage.dart';

class StaticGameData {
  final List<Difficulty> difficulties;
  final List<Job> jobs;
  final List<TraitData> traits;
  final List<Region> regions;
  final List<QuestType> questTypes;
  final List<QuestPool> questPools;
  final List<PersonName> personNames;
  final List<TravelEvent> travelEvents;
  final List<Facility> facilities;
  final List<Rank> ranks;
  final List<MercenaryWage> mercenaryWages;

  const StaticGameData({
    required this.difficulties,
    required this.jobs,
    required this.traits,
    required this.regions,
    required this.questTypes,
    required this.questPools,
    required this.personNames,
    required this.travelEvents,
    required this.facilities,
    required this.ranks,
    required this.mercenaryWages,
  });
}

final staticDataProvider = FutureProvider<StaticGameData>((ref) async {
  final appDir = await getApplicationDocumentsDirectory();
  final cacheDir = Directory('${appDir.path}/cache');
  final dataLoader = DataLoader(cacheDir: cacheDir);

  return StaticGameData(
    difficulties: dataLoader.loadFromCache('difficulties', Difficulty.fromJson),
    jobs: dataLoader.loadFromCache('jobs', Job.fromJson),
    traits: dataLoader.loadFromCache('traits', TraitData.fromJson),
    regions: dataLoader.loadFromCache('regions', Region.fromJson),
    questTypes: dataLoader.loadFromCache('quest_types', QuestType.fromJson),
    questPools: dataLoader.loadFromCache('quest_pools', QuestPool.fromJson),
    personNames: dataLoader.loadFromCache('person_names', PersonName.fromJson),
    travelEvents: dataLoader.loadFromCache('travel_events', TravelEvent.fromJson),
    facilities: dataLoader.loadFromCache('facilities', Facility.fromJson),
    ranks: dataLoader.loadFromCache('ranks', Rank.fromJson),
    mercenaryWages: dataLoader.loadFromCache('mercenary_wages', MercenaryWage.fromJson),
  );
});
```

- [ ] **Step 2: main.dart 수정**

Supabase 초기화 + SyncService 호출 추가. 싱크 실패 시(첫 실행 + 오프라인) 에러 화면 표시:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/supabase_initializer.dart';
import 'package:band_of_mercenaries/core/data/sync_service.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/core/providers/game_state_provider.dart';
import 'package:band_of_mercenaries/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveInitializer.initialize();
  await SupabaseInitializer.initialize();
  runApp(const ProviderScope(child: AppBootstrap()));
}

class AppBootstrap extends ConsumerStatefulWidget {
  const AppBootstrap({super.key});

  @override
  ConsumerState<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<AppBootstrap> {
  late Future<SyncStatus> _syncFuture;

  @override
  void initState() {
    super.initState();
    _syncFuture = _performSync();
  }

  Future<SyncStatus> _performSync() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/cache');
    final syncService = SyncService(
      client: SupabaseInitializer.client,
      dataLoader: DataLoader(cacheDir: cacheDir),
    );
    return syncService.sync();
  }

  void _retry() {
    setState(() {
      _syncFuture = _performSync();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<SyncStatus>(
      future: _syncFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('데이터 동기화 중...'),
                  ],
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('서버 연결에 실패했습니다.'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('재시도'),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return const _PostSyncApp();
      },
    );
  }
}

class _PostSyncApp extends ConsumerWidget {
  const _PostSyncApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staticData = ref.watch(staticDataProvider);

    return staticData.when(
      data: (_) {
        final userData = ref.watch(userDataProvider);
        if (userData == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(userDataProvider.notifier).initializeNewGame();
          });
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        return _IdleRewardWrapper(child: const BandOfMercenariesApp());
      },
      loading: () => const MaterialApp(
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => MaterialApp(
        home: Scaffold(body: Center(child: Text('데이터 로딩 실패: $e'))),
      ),
    );
  }
}

class _IdleRewardWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const _IdleRewardWrapper({required this.child});

  @override
  ConsumerState<_IdleRewardWrapper> createState() => _IdleRewardWrapperState();
}

class _IdleRewardWrapperState extends ConsumerState<_IdleRewardWrapper> {
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      _checked = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkIdleReward());
    }
    return widget.child;
  }

  void _checkIdleReward() {
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    final lastActiveMs = settingsBox.get('lastActiveTime') as int?;
    if (lastActiveMs == null) return;

    final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
    final now = DateTime.now();
    final absentMinutes = now.difference(lastActive).inMinutes;

    if (absentMinutes < 1) return;

    final rewardMinutes = absentMinutes.clamp(0, 480);
    final reward = rewardMinutes;

    if (reward <= 0) return;

    ref.read(userDataProvider.notifier).addGold(reward);

    if (mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('부재 보상'),
          content: Text(
            '${absentMinutes > 480 ? "8시간 이상" : "$absentMinutes분"} 동안 부재하셨습니다.\n'
            '${reward}G를 획득했습니다!',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }

    settingsBox.put('lastActiveTime', now.millisecondsSinceEpoch);
  }
}
```

- [ ] **Step 3: app.dart 수정 — 포그라운드 복귀 시 싱크 트리거**

`_MainShellState`의 `didChangeAppLifecycleState`에 싱크 로직 추가:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:band_of_mercenaries/core/data/hive_initializer.dart';
import 'package:band_of_mercenaries/core/data/supabase_initializer.dart';
import 'package:band_of_mercenaries/core/data/sync_service.dart';
import 'package:band_of_mercenaries/core/data/data_loader.dart';
import 'package:band_of_mercenaries/core/theme/app_theme.dart';
import 'package:band_of_mercenaries/core/providers/static_data_provider.dart';
import 'package:band_of_mercenaries/shared/widgets/bottom_nav_bar.dart';
import 'package:band_of_mercenaries/features/home/view/home_screen.dart';
import 'package:band_of_mercenaries/features/movement/view/movement_screen.dart';
import 'package:band_of_mercenaries/features/quest/view/dispatch_screen.dart';
import 'package:band_of_mercenaries/features/mercenary/view/recruit_screen.dart';
import 'package:band_of_mercenaries/features/settings/view/settings_screen.dart';

final currentTabProvider = StateProvider<int>((ref) => 2);

class BandOfMercenariesApp extends StatelessWidget {
  const BandOfMercenariesApp({super.key});

  static const double _maxMobileWidth = 430;
  static const double _maxMobileHeight = 932;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Band of Mercenaries',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const _MobileFrame(),
    );
  }
}

class _MobileFrame extends StatelessWidget {
  const _MobileFrame();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A1A),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: BandOfMercenariesApp._maxMobileWidth,
            maxHeight: BandOfMercenariesApp._maxMobileHeight,
          ),
          child: const MainShell(),
        ),
      ),
    );
  }
}

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> with WidgetsBindingObserver {
  static const _screens = [
    MovementScreen(),
    DispatchScreen(),
    HomeScreen(),
    RecruitScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveLastActiveTime();
    }
    if (state == AppLifecycleState.resumed) {
      _syncOnResume();
    }
  }

  void _saveLastActiveTime() {
    final settingsBox = Hive.box(HiveInitializer.settingsBoxName);
    settingsBox.put('lastActiveTime', DateTime.now().millisecondsSinceEpoch);
  }

  Future<void> _syncOnResume() async {
    final appDir = await getApplicationDocumentsDirectory();
    final cacheDir = Directory('${appDir.path}/cache');
    final syncService = SyncService(
      client: SupabaseInitializer.client,
      dataLoader: DataLoader(cacheDir: cacheDir),
    );

    final status = await syncService.sync();
    if (status == SyncStatus.updated || status == SyncStatus.fullDownload) {
      // 캐시가 갱신됨 → staticDataProvider 무효화하여 새 데이터 로딩
      ref.invalidate(staticDataProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = ref.watch(currentTabProvider);

    return Scaffold(
      body: SafeArea(child: _screens[currentTab]),
      bottomNavigationBar: BottomNavBar(
        currentIndex: currentTab,
        onTap: (index) => ref.read(currentTabProvider.notifier).state = index,
      ),
    );
  }
}
```

- [ ] **Step 4: 정적 분석 확인**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && flutter analyze`
Expected: 에러 없음

- [ ] **Step 5: 커밋**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
git add band_of_mercenaries/lib/core/providers/static_data_provider.dart band_of_mercenaries/lib/main.dart band_of_mercenaries/lib/app.dart
git commit -m "feat: integrate SyncService into app lifecycle for Supabase data sync"
```

---

## Task 10: Flutter — 기존 파일 정리 + 테스트 업데이트

**Files:**
- Delete: `lib/core/data/json_loader.dart`
- Delete: `assets/json/*.json` (11개)
- Delete: `test/core/data/json_loader_test.dart`

- [ ] **Step 1: json_loader.dart 삭제**

```bash
cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries
rm lib/core/data/json_loader.dart
```

- [ ] **Step 2: assets/json/ 디렉토리 삭제**

```bash
cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries
rm -rf assets/json/
```

- [ ] **Step 3: json_loader_test.dart 삭제**

```bash
cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries
rm test/core/data/json_loader_test.dart
```

- [ ] **Step 4: json_loader import 참조 검색 및 제거**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && grep -rn 'json_loader' lib/ --include='*.dart' | grep -v '.g.dart' | grep -v '.freezed.dart'`

나오는 모든 import 문을 제거한다. static_data_provider.dart는 이미 Task 9에서 수정 완료.

- [ ] **Step 5: 전체 테스트 실행**

Run: `cd /Users/radiogaga/git/band-of-mercenaries/band_of_mercenaries && flutter test`
Expected: 모든 테스트 통과 (json_loader_test는 삭제됨, data_loader_test는 통과)

- [ ] **Step 6: 커밋**

```bash
cd /Users/radiogaga/git/band-of-mercenaries
git add -A band_of_mercenaries/
git commit -m "refactor: remove bundled JSON files and JsonLoader, replaced by Supabase sync"
```

---

## Task 11: 통합 검증

- [ ] **Step 1: .env에 실제 Supabase 연결 정보 설정 확인**

`band_of_mercenaries/.env`에 실제 `SUPABASE_URL`과 `SUPABASE_ANON_KEY`가 설정되어 있는지 확인.

- [ ] **Step 2: Supabase data_versions 테이블 확인**

Supabase 대시보드에서 `data_versions` 테이블에 11개 행이 존재하고, 각 `version`이 1인지 확인.

- [ ] **Step 3: 첫 실행 시나리오 테스트**

앱의 캐시 디렉토리가 비어 있는 상태에서 앱 실행:
- "데이터 동기화 중..." 로딩 표시
- 전체 11개 테이블 다운로드
- 게임 화면 진입
- 캐시 디렉토리에 11개 JSON 파일 생성 확인

- [ ] **Step 4: 오프라인 재실행 테스트**

네트워크를 끊은 상태에서 앱 재실행:
- 캐시에서 데이터 로딩
- 정상적으로 게임 화면 진입

- [ ] **Step 5: 델타 싱크 테스트**

1. operation-bom에서 임의의 테이블 데이터 수정
2. "버전 발행" 버튼 클릭 (v1 → v2)
3. Flutter 앱 재실행
4. 해당 테이블만 다운로드되고 캐시 갱신되는지 확인

- [ ] **Step 6: 첫 실행 + 오프라인 에러 테스트**

캐시 없는 상태 + 네트워크 끊김:
- "서버 연결에 실패했습니다." + "재시도" 버튼 표시

- [ ] **Step 7: 최종 커밋 (필요 시)**

남은 수정사항이 있으면 커밋.
