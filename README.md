# Owlia

🦉 AI assistant deployment scripts powered by [OpenClaw](https://openclaw.ai).

## Android (Termux)

Install OpenClaw on any Android device via Termux:

```bash
curl -sL owlia.bot/android | bash
```

### Requirements

- Android device with 2GB+ RAM
- [Termux](https://f-droid.org/packages/com.termux/) from F-Droid (not Play Store)

### What it does

1. Installs Node.js and dependencies
2. Installs OpenClaw CLI
3. Creates basic configuration
4. Sets up background running (wake lock)
5. Optionally configures auto-start on boot
6. Runs the onboarding wizard

### Manual install

If you prefer step-by-step:

```bash
# In Termux
pkg update && pkg install nodejs-lts git
npm install -g openclaw
openclaw onboard
```

## More platforms

Coming soon:
- iOS (Shortcuts + a]Shelf)
- Linux (one-liner)
- Raspberry Pi

## License

MIT
