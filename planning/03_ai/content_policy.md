# Content Policy & Mature Themes

This document addresses the game's handling of mature content and its implications for AI model selection.

## Content Philosophy

**Lagos Stories is an adult simulation game**. Not pornographic in nature, but realistic in depicting:

- Crime (theft, fraud, violence, corruption)
- Illegal activities (bribery, smuggling, extortion)
- Violence (fights, threats, potential death)
- Mature themes (exploitation, injustice, moral complexity)
- Explicit language (appropriate to Lagos street culture)
- Substance use (alcohol, drugs)
- Sexual relationships (relationships exist, not explicit scenes)

## Content Goals

**What We ARE Trying to Do**:
- Simulate a realistic urban environment with all its complexity
- Allow players to explore moral gray areas
- Portray crime and corruption as systems, not glorification
- Respect the setting (Lagos) with cultural authenticity
- Support investigative gameplay (crimes exist to be solved)
- Show consequences of actions (violence leads to trauma, arrest, death)
- Enable emergent stories about power, survival, and humanity

**What We ARE NOT Trying to Do**:
- Create pornographic or sexually explicit content
- Glorify violence or crime for shock value
- Encourage real-world illegal behavior
- Be gratuitously offensive
- Exploit trauma for entertainment

## Content Boundaries

### Allowed & Expected:
- **Crime**: Theft, fraud, bribery, extortion, smuggling, violence
- **Corruption**: Bribing officials, police misconduct, institutional failure
- **Violence**: Fights, threats, weapons, potential character death
- **Morally Complex Choices**: Gray areas where right answer isn't clear
- **Exploitation & Injustice**: Economic inequality, abuse of power
- **Adult Language**: Realistic dialogue including profanity
- **Substance Use**: Alcohol, drugs (as part of world, not focus)
- **Relationships**: Romance, affairs, betrayal (narrative, not explicit)

### Not Included:
- **Explicit Sexual Content**: Relationships exist, scenes are fade-to-black
- **Sexual Violence**: Not simulated
- **Child Harm**: NPCs can be children, but violence against children not simulated in detail
- **Torture Porn**: Violence has consequences, not gratuitous
- **Hate Speech**: Characters may have biases (simulation), but not player-directed hate

### Gray Areas (Design Choices Needed):

**Human Trafficking**:
- Exists as a real Lagos issue
- Can be part of investigations/antagonist activity
- Not player-actionable (can't traffic people)
- Portrayed as serious crime with consequences

**Drug Trade**:
- Exists in world
- Can be involved in narratives
- Player can engage (as user, small-time dealer, investigator)
- Addiction has mechanical consequences (status effects)

**Police Violence**:
- Part of Lagos reality
- Can happen to player or NPCs
- Portrayed with consequences (trauma, injustice)
- Not gratuitous

## AI Model Implications

### Local Models (Primary Approach)

**Advantages for Mature Content**:
- ✅ **No Content Filters**: Open-source models run locally have no restrictions
- ✅ **Full Control**: We control prompting and output
- ✅ **Privacy**: No external parties reviewing content
- ✅ **Consistency**: Behavior doesn't change based on API provider policies

**Suitable Local Models**:
- **Mistral 7B/13B/22B**: No content filtering, handles mature themes well
- **Llama 2/3 (uncensored variants)**: Community fine-tunes without safety layers
- **Nous-Hermes**: Explicitly designed for unrestricted output
- **WizardLM**: Good for complex scenarios
- **Vicuna**: Handles nuanced content

**Prompting Strategy for Local Models**:
- Be explicit about simulation context
- Frame content as narrative/fictional
- Request factual, consequences-aware output
- Avoid euphemisms (be clear about what's happening)

### API Models (Optional)

**Challenges for Mature Content**:
- ❌ **Content Policies**: OpenAI, Anthropic, Google have strict policies against violent/illegal content
- ❌ **Refusals**: May refuse to generate crime, violence, morally complex scenarios
- ❌ **Inconsistency**: Policies change, behavior varies
- ❌ **Account Risk**: Repeated mature content might trigger warnings

**API Viability**:
- **OpenAI GPT-4**: Likely to refuse explicit crime, violence simulation
- **Anthropic Claude**: More nuanced, might work with careful prompting
- **Google Gemini**: Strict policies, probably won't work
- **Cohere**: More permissive, might be suitable

**If Using APIs**:
- Use for less sensitive tasks (world generation, descriptions)
- Reserve local models for crime, violence, morally complex content
- Provide clear disclaimer about simulation nature
- Have fallback to local model if API refuses

### Recommended Approach

**Hybrid Model Assignment**:

**Local Models (Uncensored)**:
- Instance Framing (may involve crime/conflict setup)
- NPC Decision Making (may choose illegal actions)
- Outcome Adjudication (consequences of violence/crime)
- Resolution & Consequences (full range of outcomes)

**API Models (Optional, Low-Risk Tasks)**:
- World Generation (mostly neutral world-building)
- Narrative Description (can be sanitized)
- Intent Interpretation (player wants to "investigate", not graphic)

**Safest Strategy**: Use only local models. This is already our primary approach, and it completely avoids content policy issues.

## Content Rating

If distributed/documented publicly:

**Appropriate Ratings**:
- **ESRB**: M for Mature (17+)
  - Blood and Gore
  - Intense Violence
  - Strong Language
  - Use of Drugs and Alcohol
  
- **PEGI**: 18
  - Extreme violence
  - Encouragement of criminal acts (in fictional context)
  - Strong language

**Content Warnings**:
- Violence and crime simulation
- Mature themes including corruption and exploitation
- Strong language
- Substance use
- Morally complex scenarios

## Implementation Guidelines

### AI Prompting

**System Prompt Template**:
```
You are simulating a realistic urban environment in Lagos, Nigeria. This simulation includes:
- Crime and violence (theft, fraud, fights, potential death)
- Corruption and morally gray situations
- Realistic consequences of illegal actions

Portray these elements realistically:
- Violence has consequences (injury, trauma, arrest, death)
- Crime is part of the world, not glorified
- NPCs have complex motivations
- Actions have moral weight

This is a fictional simulation for adult players. Be direct and clear about events without being gratuitous.
```

### Content Generation Rules

**Violence**:
- Describe what happens and consequences
- Don't focus on graphic gore details
- Show emotional/physical aftermath
- Mechanical effects (injury status, death event)

**Crime**:
- Simulate realistically (can succeed or fail)
- Show investigation/pursuit
- Consequences exist (arrest, reputation, guilt)

**Language**:
- Use appropriate language for setting (Nigerian English, Pidgin, profanity)
- Not excessive or gratuitous

### Player Agency

**Players Can**:
- Investigate crimes
- Commit crimes (with consequences)
- Use violence (with consequences)
- Bribe officials
- Make morally complex choices

**Consequences Are Real**:
- Crime → arrest risk, reputation loss, guilt/stress
- Violence → injury, death (yours or others), trauma, legal trouble
- Bribery → corruption propagation, dependency, exposure risk

**No Judgment**:
- Game doesn't tell you you're "bad" for choosing crime
- But NPCs, organizations, and systems react realistically
- Player decides their own moral compass

## Testing & Boundaries

During development:
- Monitor AI outputs for gratuitous content
- Ensure consequences are meaningful
- Test that mature content serves narrative, not shock
- Get feedback from playtesters about comfort levels
- Be prepared to adjust tone/detail level

## Community & Distribution

**If Made Public**:
- Clear content warnings
- Age gates (18+)
- Explicit about simulation nature
- Community guidelines for discussing/sharing content
- No sharing of outputs designed to be offensive

**Open Source Considerations**:
- Code is open, prompts are visible
- Community can modify for their comfort level
- We're not responsible for modifications
- But default should be thoughtful, not gratuitous

## Summary

**Bottom Line**: Lagos Stories is an adult simulation that handles crime, violence, and moral complexity realistically as part of the gameplay. This is:

1. **Compatible with local LLMs**: No issues, this is our primary approach
2. **Potentially problematic with API models**: Some providers may refuse content
3. **Solution**: Use local models for sensitive content, APIs only for safe tasks
4. **Best Practice**: Stick with local-only approach (already our design)

The mature content is **integral to the simulation**, not gratuitous. We're simulating a real city with real problems, allowing players to engage with complex moral scenarios. Local AI models give us the freedom to do this responsibly without external content restrictions.

