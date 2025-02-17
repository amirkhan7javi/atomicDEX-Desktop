import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

import "../../Components"
import "../../Constants"

// Ticker selectors.
Row
{
    id: selectors

    TickerSelector
    {
        id: selectorLeft

        width: parent.width * 0.45
        height: parent.height

        left_side: true
        ticker_list: API.app.trading_pg.market_pairs_mdl.left_selection_box
        ticker: left_ticker
    }

    SwapIcon
    {
        width: parent.width * 0.1
        anchors.verticalCenter: parent.verticalCenter
        top_arrow_ticker: selectorLeft.ticker
        bottom_arrow_ticker: selectorRight.ticker
        hovered: swap_button.containsMouse

        DefaultMouseArea
        {
            id: swap_button
            anchors.fill: parent
            hoverEnabled: true
            onClicked:
            {
                if (!block_everything)
                    setPair(true, right_ticker)
            }
        }
    }

    TickerSelector
    {
        id: selectorRight

        width: parent.width * 0.45
        height: parent.height

        left_side: false
        ticker_list: API.app.trading_pg.market_pairs_mdl.right_selection_box
        ticker: right_ticker
    }
}
