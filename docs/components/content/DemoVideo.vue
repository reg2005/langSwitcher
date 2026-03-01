<template>
  <div :style="{ display: 'flex', justifyContent: 'center', width: '100%' }">
    <video
      autoplay
      loop
      playsinline
      muted
      :src="src"
      :style="{ width: '100%', maxWidth: maxWidth, borderRadius: '12px', boxShadow: '0 4px 24px rgba(0,0,0,0.12)' }"
    />
  </div>
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
