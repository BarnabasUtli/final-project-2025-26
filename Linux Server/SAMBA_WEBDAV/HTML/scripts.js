// Globális particle config
const particleConfig = {
  background: { color: "transparent" },
  fpsLimit: 60,
  particles: {
    number: { value: 80, density: { enable: true, area: 800 } },
    color: { value: "#d4af37" },
    shape: { type: "circle" },
    opacity: { value: 0.5 },
    size: { value: { min: 1, max: 4 } },
    links: {
      enable: true,
      distance: 120,
      color: "#ffffff",
      opacity: 0.3,
      width: 1
    },
    move: {
      enable: true,
      speed: 0.2,
      direction: "none",
      outModes: "out"
    }
  },
  interactivity: {
    events: {
      onHover: { enable: true, mode: "repulse" },
      onClick: { enable: true, mode: "push" }
    },
    modes: {
      repulse: { distance: 120 },
      push: { quantity: 4 }
    }
  },
  detectRetina: true
};

// Betöltés
window.addEventListener("DOMContentLoaded", () => {
  tsParticles.load("particles-js", particleConfig);
});
