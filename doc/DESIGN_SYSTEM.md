# ISAAC Interface Design System

Practical guidance for extending ISAAC's server-rendered interface with a consistent, minimal TailwindCSS visual language.

## Principles

- **Quiet and functional**: Prioritize content, task completion, and clear states over decoration.
- **Server-rendered first**: Use semantic HTML, Rails helpers, and Turbo before introducing custom JavaScript.
- **One neutral palette**: Use gray for structure and reserve color for status, danger, and chat identity.
- **Responsive by default**: Every page must remain usable at narrow mobile widths without a separate layout.
- **Local utilities over premature components**: Repeat stable Tailwind utility groups until a genuinely reusable Rails partial or helper emerges.

## Page Structure

Use a centered page shell with responsive horizontal padding:

```erb
<main class="mx-auto max-w-3xl px-4 py-8 sm:px-6">
  ...
</main>
```

- Use `max-w-3xl` for dashboards, indexes, and chats.
- Use `max-w-xl` for settings and focused forms.
- Use `max-w-md` for authentication.
- Use `min-h-dvh` when a page needs full-height behavior, such as chat.
- Keep page-level layout in `<main>` and use `<header>`, `<section>`, and `<nav>` landmarks where appropriate.

Page headers use a quiet parent link, title, optional supporting copy, and a bottom border:

```erb
<header class="border-b border-gray-200 pb-5">
  <%= link_to "Dashboard", dashboards_path, class: "text-sm text-gray-500 hover:text-gray-950" %>
  <h1 class="mt-1 text-2xl font-semibold text-gray-950">Page Title</h1>
  <p class="mt-1 text-sm text-gray-500">A short explanation of this page.</p>
</header>
```

For an action aligned opposite the title, add `flex items-center justify-between gap-4` to the header. Apply `shrink-0` to the action so it remains legible.

## Typography

| Purpose | Utilities |
|---|---|
| Page title | `text-2xl font-semibold text-gray-950` |
| Section title | `text-lg font-medium text-gray-950` |
| Body | `text-sm leading-6 text-gray-800` |
| Supporting text | `text-sm text-gray-500` |
| Table heading | `text-xs font-medium uppercase tracking-wide text-gray-500` |
| Metadata | `text-xs text-gray-400` |

Keep labels and navigation concise. Supporting copy should explain consequences or next steps, not restate the heading.

## Color

- `gray-950`: primary text and primary actions
- `gray-800` / `gray-700`: body text and secondary actions
- `gray-500` / `gray-400`: supporting text and metadata
- `gray-300` / `gray-200`: controls and dividers
- `green-*`: successful or connected states
- `red-*`: errors and destructive actions
- White is the default page and control background

Do not introduce accent colors for routine navigation. Color should communicate meaning.

## Actions

Primary actions are dark, compact, and rounded:

```erb
class: "rounded-md bg-gray-950 px-4 py-2 text-sm font-medium text-white hover:bg-gray-800"
```

Secondary bordered actions use:

```erb
class: "rounded-md border border-gray-300 px-4 py-2 text-sm font-medium text-gray-800 hover:bg-gray-50"
```

Quiet actions use `text-sm font-medium text-gray-600 hover:text-gray-950`. Destructive actions use `text-red-700 hover:text-red-900` and must not look like primary actions.

- Use `link_to` for navigation.
- Use `button_to` or `form_with` for state changes.
- Use `data: { turbo_confirm: "..." }` for destructive confirmations.
- Preserve `data: { turbo: false }` when an external authentication flow requires a full page request.
- Return HTTP 303 after successful modifying requests and 422 when rendering validation errors.

## Forms

Labels are always visible unless the surrounding interface makes the field purpose unambiguous:

```erb
<%= form.label :email, class: "block text-sm font-medium text-gray-800" %>
<%= form.email_field :email,
                     class: "mt-2 block w-full rounded-md border border-gray-300 px-3 py-2 text-gray-950 placeholder:text-gray-400 focus:border-gray-500 focus:outline-none focus:ring-1 focus:ring-gray-500" %>
```

- Stack fields vertically and use `mt-2` between label and control.
- Use `mt-6 flex items-center gap-4` for form actions.
- Add concise help text with `mt-2 text-sm text-gray-500` when a choice has lasting effects.
- Use appropriate `autocomplete`, input type, `required`, and `autofocus` attributes.
- Text areas may use `resize-none` when their intended height is constrained.

Validation summaries use a red border and pale background:

```erb
class: "mb-6 rounded-md border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-800"
```

Keep `id="error_explanation"` for testability and conventional Rails behavior.

## Collections

Use border-separated tables for compact account settings and lists for conversational content.

- Wrap tables in `overflow-x-auto` for mobile layouts.
- Use `min-w-full text-left text-sm` on the table.
- Separate rows with `divide-y divide-gray-200`.
- Keep row actions right-aligned and `whitespace-nowrap`.
- Preserve a useful text label for every action; do not default to unlabeled icons.

Empty states use generous space and one clear next action:

```erb
<div class="py-16 text-center">
  <p class="text-gray-600">Nothing here yet.</p>
  ...
</div>
```

## Feedback

Global notices and alerts live in the application layout and use `data-turbo-temporary` so Turbo does not restore stale feedback from its cache.

- Notices: green border/background with `role="status"`
- Alerts: red border/background with `role="alert"`
- Inline validation stays next to its form rather than using a flash
- Loading or asynchronous regions should use `aria-live="polite"` where updates need announcement

## Chat

- User messages align right in a dark rounded bubble.
- Assistant messages align left without a heavy container.
- Keep message content `whitespace-pre-wrap` and use readable `leading-6` spacing.
- Keep the composer visible with a sticky white footer and a top divider.
- Render the same message partials for initial HTML and Turbo Stream broadcasts.
- Subscribe with a signed `turbo_stream_from` stream and perform model work in a background job.

## Accessibility

- Use semantic landmarks and heading order.
- Give tables scoped column headings.
- Pair every form control with a label.
- Never communicate status through color alone; include text such as "Connected".
- Use visible focus rings on controls.
- Use `aria-hidden="true"` only for decorative elements.
- Keep touch targets padded and avoid icon-only destructive controls.

## Review Checklist

- The page works at mobile and desktop widths.
- Navigation and modifying actions use the correct Rails helper.
- Empty, populated, validation, success, and failure states are styled.
- Current-user resources remain scoped in the controller.
- Turbo responses and redirects follow `doc/TURBO.md`.
- Existing copy and semantic selectors required by tests remain intact.
- Tailwind utilities follow the neutral palette and spacing conventions above.
