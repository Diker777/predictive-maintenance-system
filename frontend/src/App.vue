<script setup lang="ts">
import Dashboard from './components/Dashboard.vue'
</script>

<template>
  <Dashboard />
</template>

<style>
/* 强制全屏样式 - 但保留UI组件样式 */
html, body, #app {
  margin: 0 !important;
  padding: 0 !important;
  box-sizing: border-box !important;
}

/* 保留必要的UI组件样式 */
input, select, button, table {
  margin: initial;
  padding: initial;
  border: initial;
}

html, body {
  height: 100vh !important;
  width: 100vw !important;
  overflow: hidden !important;
  margin: 0 !important;
  padding: 0 !important;
  position: fixed !important;
  top: 0 !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  background: #0a1f37 !important;
}

#app {
  height: 100vh !important;
  width: 100vw !important;
  overflow: hidden !important;
  position: fixed !important;
  top: 0 !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  background: #0a1f37 !important;
}

/* 强制DataV组件全屏 */
.dv-full-screen-container {
  height: 100vh !important;
  width: 100vw !important;
  position: fixed !important;
  top: 0 !important;
  left: 0 !important;
  right: 0 !important;
  bottom: 0 !important;
  overflow: hidden !important;
}

/* 响应式字体大小适配 */
@media screen and (min-width: 1920px) {
  .panel-header {
    font-size: 16px !important;
  }
}

@media screen and (max-width: 1366px) {
  .panel-header {
    font-size: 12px !important;
  }
}

@media screen and (min-height: 900px) {
  .kpi-value {
    font-size: 18px !important;
  }
}

@media screen and (max-height: 720px) {
  .kpi-value {
    font-size: 14px !important;
  }
}
</style>
