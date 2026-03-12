// NOTE: Change "com.plume.app" to match your actual applicationId in build.gradle
package com.plume.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

class PlumeWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        for (widgetId in appWidgetIds) {
            updateWidget(context, appWidgetManager, widgetId)
        }
    }

    private fun updateWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        widgetId: Int,
    ) {
        val views = RemoteViews(context.packageName, R.layout.plume_widget)
        val data  = HomeWidgetPlugin.getData(context)

        val balance    = data.getString("balance",       "— F") ?: "— F"
        val isPositive = data.getBoolean("is_positive",  true)
        val todayExp   = data.getString("today_expenses","0 F") ?: "0 F"
        val budgetRem  = data.getString("budget_remaining", "") ?: ""
        val hasBudget  = data.getBoolean("has_budget",   false)
        val updatedAt  = data.getString("updated_at",    "--:--") ?: "--:--"

        views.setTextViewText(R.id.widget_balance,    balance)
        views.setTextViewText(R.id.widget_today,      todayExp)
        views.setTextViewText(R.id.widget_updated_at, updatedAt)

        // Budget remaining
        if (hasBudget && budgetRem.isNotEmpty()) {
            views.setViewVisibility(R.id.widget_budget_container,
                android.view.View.VISIBLE)
            views.setTextViewText(R.id.widget_budget, budgetRem)
            val color = if (budgetRem.startsWith("-"))
                android.graphics.Color.parseColor("#FFFF5252")
            else
                android.graphics.Color.parseColor("#FF69F0AE")
            views.setTextColor(R.id.widget_budget, color)
        } else {
            views.setViewVisibility(R.id.widget_budget_container,
                android.view.View.GONE)
        }

        // Balance color (red if negative)
        views.setTextColor(
            R.id.widget_balance,
            if (isPositive) android.graphics.Color.WHITE
            else android.graphics.Color.parseColor("#FFFF5252"))

        appWidgetManager.updateAppWidget(widgetId, views)
    }
}