# App Component

## Screen Template

```tsx
import { View, Text, ScrollView } from "react-native";
import { useTranslation } from "react-i18next";
import { SafeAreaView } from "react-native-safe-area-context";
import { useSession } from "@/lib/auth";
import { trpc } from "@/lib/trpc";

export default function MyScreen() {
  const { t } = useTranslation();
  const { data: session } = useSession();

  const itemsQuery = trpc.my.list.useQuery(undefined, {
    enabled: !!session,
  });

  const items = itemsQuery.data ?? [];

  return (
    <SafeAreaView style={{ flex: 1 }} edges={["top"]}>
      <ScrollView contentContainerStyle={{ paddingBottom: 32 }}>
        <View style={{ paddingHorizontal: 20, paddingTop: 16, gap: 16 }}>
          <Text style={{ fontSize: 24, fontFamily: "Outfit_700Bold", color: "#030712" }}>
            {t("my.title")}
          </Text>
          {/* content */}
        </View>
      </ScrollView>
    </SafeAreaView>
  );
}
```

## Key Patterns

### tRPC

```tsx
import { trpc } from "@/lib/trpc";

// Query
const query = trpc.my.list.useQuery(undefined, { enabled: !!session });

// Mutation
const mutation = trpc.my.create.useMutation();
mutation.mutate({ name: "Test" });
```

### Auth

```tsx
import { useSession } from "@/lib/auth";
const { data: session } = useSession();
const userName = session?.user?.name ?? "";
```

### i18n

```tsx
import { useTranslation } from "react-i18next";
const { t } = useTranslation();
// Interpolation uses {{variable}} (i18next style, NOT {variable})
t("home.greeting")
t("lesson.cardsCount", { count: 5 })
```

### Navigation

```tsx
import { router } from "expo-router";
router.push("/(app)/lesson/123");
router.back();
```

### Styling

- Inline style objects, NOT StyleSheet.create (current convention)
- Color constants at top of file: `const PRIMARY = "#012CD9"`
- Fonts: `"Outfit_400Regular"`, `"Outfit_600SemiBold"`, `"Outfit_700Bold"`


### NativeWind + Reanimated

NativeWind `className` does NOT work on `Animated.View` on web. Always wrap:

```tsx
// BAD
<Animated.View className="flex-1 bg-white" />

// GOOD
<Animated.View style={{ flex: 1 }}>
  <View className="flex-1 bg-white">{children}</View>
</Animated.View>
```
