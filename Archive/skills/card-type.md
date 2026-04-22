# Card Type Creator

Workflow for adding a new card type to Diane.

## Step 1: Shared Schema

Add the type to `cardTypeEnum` in `packages/shared/src/schemas.ts`:

```ts
export const cardTypeEnum = z.enum([
  "flashcard",
  "multiple_choice",
  "true_false",
  "fill_blank",
  "free_response",
  "note",
  "podcast",
  "new_type",  // <-- add here
]);
```

## Step 2: Database Schema (if needed)

Add any new columns to the `cards` table in `apps/api/src/db/schema.ts`. Typed JSON for structured data:

```ts
myData: json("my_data").$type<MyDataType>(),
```

Then run `pnpm db:generate && pnpm db:migrate`.

## Step 3: API Router

Update `apps/api/src/trpc/routers/cards.ts` to handle the new type in create/update/review logic.

## Step 4: React Native Component

Create `apps/app/components/card/NewTypeCard.tsx`:

```tsx
import { View, Text, Pressable } from "react-native";
import { useState } from "react";
import type { Card } from "@diane/shared";

interface NewTypeCardProps {
  card: Card;
  onUpdate?: (data: any) => void;
  renderProgress?: () => React.ReactNode;
}

export function NewTypeCard({
  card,
  onUpdate,
  renderProgress,
}: NewTypeCardProps) {
  const [showAnswer, setShowAnswer] = useState(false);

  const handleCardUpdate = async (data: any) => {
    onUpdate?.(data);
  };

  return (
    <Pressable
      onPress={() => setShowAnswer(!showAnswer)}
      style={{
        borderRadius: 16,
        overflow: "hidden",
        backgroundColor: "#ffffff",
      }}
    >
      <View style={{ backgroundColor: "#F3F4F6", padding: 16 }}>
        {renderProgress?.()}
        {/* question */}
        <Text
          style={{
            fontSize: 16,
            fontFamily: "Outfit_600SemiBold",
            color: "#030712",
          }}
        >
          {/* card question content */}
        </Text>
      </View>
      {showAnswer && (
        <View style={{ padding: 16, backgroundColor: "#ffffff", borderTopWidth: 1, borderTopColor: "#E5E7EB" }}>
          {/* answer */}
          <Text
            style={{
              fontSize: 16,
              fontFamily: "Outfit_400Regular",
              color: "#374151",
            }}
          >
            {/* card answer content */}
          </Text>
        </View>
      )}
    </Pressable>
  );
}
```

Key patterns:
- Props: `card: Card` from `@diane/shared`, `onUpdate` callback, `renderProgress` slot
- State: `showAnswer` via `useState`
- Styling: inline style objects, Outfit fonts (`Outfit_600SemiBold`, `Outfit_400Regular`)
- Parent component handles tRPC mutation + query invalidation, passes `onUpdate` callback

## Step 5: Review Integration

Add the new card type to the review screen (`apps/app/app/review.tsx`) switch/conditional:

```tsx
import { NewTypeCard } from "@/components/card/NewTypeCard";
import { trpc } from "@/lib/trpc";
import { useSession } from "@/lib/auth";

export default function ReviewScreen() {
  const { data: session } = useSession();
  const { t } = useTranslation();

  const cardsQuery = trpc.cards.list.useQuery(undefined, {
    enabled: !!session,
  });

  const updateMutation = trpc.cards.update.useMutation({
    onSuccess: () => {
      cardsQuery.refetch();
    },
  });

  const renderCard = (card: Card) => {
    switch (card.type) {
      case "flashcard":
        return <FlashcardCard card={card} onUpdate={updateMutation.mutate} />;
      case "multiple_choice":
        return <MultipleChoiceCard card={card} onUpdate={updateMutation.mutate} />;
      case "new_type":
        return <NewTypeCard card={card} onUpdate={updateMutation.mutate} />;
      // ... other types
      default:
        return null;
    }
  };

  return (
    <SafeAreaView style={{ flex: 1 }}>
      <ScrollView>
        {cardsQuery.data?.map((card) => (
          <View key={card.id} style={{ marginBottom: 16 }}>
            {renderCard(card)}
          </View>
        ))}
      </ScrollView>
    </SafeAreaView>
  );
}
```

Key patterns:
- Use `expo-router` for navigation (already in place at `apps/app/app/review.tsx`)
- tRPC hooks: `trpc.cards.list.useQuery()`, `trpc.cards.update.useMutation()`
- `useSession` from `@/lib/auth` for auth state
- `useTranslation` from `react-i18next` for i18n
- Mutation success callback calls `refetch()` to invalidate query

## Step 6: Translations

Add French translations in `apps/app/i18n/fr.json` only. CI auto-translates other languages:

```json
{
  "card": {
    "new_type": {
      "question": "Question...",
      "answer": "Réponse...",
      "placeholder": "..."
    }
  }
}
```

Reference translations in component via `useTranslation()`:
```tsx
const { t } = useTranslation();
const questionText = t("card.new_type.question");
```

## Step 7: Tests

Add tests in `apps/api/src/trpc/routers/cards.test.ts` for create/review with the new type.
