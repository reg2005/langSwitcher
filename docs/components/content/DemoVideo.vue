<template>
  <video
    autoplay
    loop
    playsinline
    muted
    :src="src"
    :style="{ width: '100%', maxWidth: maxWidth, borderRadius: '12px' }"
  />
</template>

<script setup lang="ts">
defineProps({
  src: {
    type: String,
    default: '/langSwitcher/langSwitch.mp4',
  },
  maxWidth: {
    type: String,
    default: '480px',
  },
})
</script>
