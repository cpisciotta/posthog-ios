import { urls } from 'scenes/urls'

export const savedInsights = {
    checkInsightIsInListView: (insightName) => {
        cy.visit(urls.savedInsights())
        cy.contains('.saved-insights table tr', insightName).should('exist')
    },
    checkInsightIsNotInListView: (insightName) => {
        cy.visit(urls.savedInsights())
        cy.contains('.saved-insights table tr', insightName).should('not.exist')
    },
    createNewInsightOfType: (insightType) => {
        cy.visit('/saved_insights/') // Should work with trailing slash just like without it
        cy.get('[data-attr=saved-insights-new-insight-dropdown]').click()
        cy.get(`[data-attr-insight-type="${insightType || 'TRENDS'}"`).click()
    },
}

export const insight = {
    applyFilter: () => {
        cy.get('[data-attr=insight-filters-add-filter-group]').click()
        cy.get('[data-attr=property-select-toggle-0]').click()
        cy.get('[data-attr=taxonomic-filter-searchfield]').click()
        cy.get('[data-attr=prop-filter-event_properties-1]').click({ force: true })
        cy.get('[data-attr=prop-val]').click()
        cy.get('[data-attr=prop-val-0]').click({ force: true })
    },
    editName: (insightName) => {
        if (insightName) {
            cy.get('[data-attr="insight-name"] [data-attr="edit-prop-name"]').click()
            cy.get('[data-attr="insight-name"] input').type(insightName)
            cy.get('[data-attr="insight-name"] [title="Save"]').click()
        }
    },
    save: () => {
        cy.get('[data-attr="insight-save-button"]').click()
        // wait for save to complete and URL to change and include short id
        cy.url().should('not.include', '/new')
    },
    addInsightToDashboard: (dashboardName) => {
        cy.intercept('PATCH', /api\/projects\/\d+\/insights\/\d+\/.*/).as('patchInsight')

        cy.get('[data-attr="save-to-dashboard-button"]').click()
        cy.get('[data-attr="dashboard-searchfield"]').type(dashboardName)
        cy.contains('[data-attr="dashboard-list-item"]', dashboardName).within(() => {
            // force clicks rather than mess around scrolling rows that exist into view
            cy.contains('button', 'Add to dashboard').click({ force: true })
            cy.wait('@patchInsight').then(() => {
                cy.contains('a', dashboardName).click({ force: true })
            })
        })
    },
}

export const dashboards = {
    createDashboardFromDefaultTemplate: (dashboardName) => {
        cy.get('[data-attr="new-dashboard"]').click()
        cy.get('[data-attr=dashboard-name-input]').clear().type(dashboardName)
        cy.get('[data-attr=copy-from-template]').click()
        cy.get('[data-attr=dashboard-select-default-app]').click()

        cy.get('[data-attr=dashboard-submit-and-go]').click()

        cy.contains(dashboardName).should('exist')
    },
    createAndGoToEmptyDashboard: (dashboardName) => {
        cy.get('[data-attr="new-dashboard"]').click()
        cy.get('[data-attr=dashboard-name-input]').clear().type(dashboardName)
        cy.get('button[data-attr="dashboard-submit-and-go"]').click()
    },
}

export const dashboard = {
    addInsightToEmptyDashboard: (insightName) => {
        cy.intercept('POST', /api\/projects\/\d+\/insights\//).as('postInsight')

        cy.get('[data-attr=dashboard-add-graph-header]').contains('Add insight').click()
        cy.get('[data-attr=toast-close-button]').click({ multiple: true })

        if (insightName) {
            cy.get('[data-attr="insight-name"] [data-attr="edit-prop-name"]').click()
            cy.get('[data-attr="insight-name"] input').type(insightName)
            cy.get('[data-attr="insight-name"] [title="Save"]').click()
        }

        cy.get('[data-attr=insight-save-button]').contains('Save & add to dashboard').click()
        cy.wait('@postInsight')
    },
}

export function createInsight(insightName) {
    savedInsights.createNewInsightOfType('TRENDS')
    insight.applyFilter()
    insight.editName(insightName)
    insight.save()
}