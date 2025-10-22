import React from 'react'

export default function Crafting({ recipes, onCraft }) {
  if (!recipes || recipes.length === 0) return null
  return (
    <div className="crafting">
      <h3>Crafting</h3>
      <div className="recipes">
        {recipes.map((recipe) => (
          <div key={recipe.id} className="recipe">
            <h4>{recipe.label}</h4>
            <div className="inputs">
              {recipe.inputs.map((input) => (
                <span key={input.name}>{input.qty}x {input.name}</span>
              ))}
            </div>
            <div className="outputs">
              {recipe.outputs.map((output) => (
                <span key={output.name}>{output.qty}x {output.name}</span>
              ))}
            </div>
            <button onClick={() => onCraft(recipe.id)}>Craft ({recipe.timeMs / 1000}s)</button>
          </div>
        ))}
      </div>
    </div>
  )
}
