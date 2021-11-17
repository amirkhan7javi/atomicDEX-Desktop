import QtQuick 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.0

import AtomicDEX.MarketMode 1.0
import AtomicDEX.TradingError 1.0
import "../../../Components"
import App 1.0
import Dex.Themes 1.0 as Dex

FloatingBackground
{
    id: root
    radius: 10

    function focusVolumeField()
    {
        input_volume.forceActiveFocus()
    }

    readonly property string total_amount: API.app.trading_pg.total_amount

    readonly property bool can_submit_trade: last_trading_error === TradingError.None

    // Will move to backend: Minimum Fee
    function getMaxBalance()
    {
        if (General.isFilled(base_ticker))
            return API.app.get_balance(base_ticker)

        return "0"
    }

    // Will move to backend: Minimum Fee
    function getMaxVolume()
    {
        // base in this orderbook is always the left side, so when it's buy, we want the right side balance (rel in the backend)
        const value = sell_mode ? API.app.trading_pg.orderbook.base_max_taker_vol.decimal :
            API.app.trading_pg.orderbook.rel_max_taker_vol.decimal

        if (General.isFilled(value))
            return value

        return getMaxBalance()
    }

    function setMinimumAmount(value) { API.app.trading_pg.min_trade_vol = value }

    Connections
    {
        target: exchange_trade
        function onBackend_priceChanged() { input_price.text = exchange_trade.backend_price; }
        function onBackend_volumeChanged() { input_volume.text = exchange_trade.backend_volume; }
    }

    ColumnLayout
    {
        id: form_layout
        width: parent.width

        ColumnLayout
        {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true
            Layout.topMargin: 20
            spacing: 15

            Item
            {
                Layout.fillWidth: true
                Layout.bottomMargin: input_volume.font.pixelSize
                height: input_volume.height

                AmountField
                {
                    id: input_price

                    left_text: qsTr("Price")
                    right_text: atomic_qt_utilities.retrieve_main_ticker(right_ticker)
                    enabled: !(API.app.trading_pg.preffered_order.price !== undefined)
                    text: backend_price
                    width: 261
                    height: 41
                    radius: 18

                    onTextChanged: setPrice(text)
                }

                DefaultText
                {
                    id: price_usd_value
                    anchors.right: input_price.right
                    anchors.top: input_price.bottom
                    anchors.topMargin: 7

                    text_value: General.getFiatText(non_null_price, right_ticker)
                    font.pixelSize: input_price.font.pixelSize
                    color: Dex.CurrentTheme.foregroundColor2

                    CexInfoTrigger {}
                }
            }


            Item
            {
                Layout.fillWidth: true
                Layout.bottomMargin: input_volume.font.pixelSize
                height: input_volume.height

                AmountField
                {
                    id: input_volume
                    width: 261
                    height: 41
                    radius: 18
                    left_text: qsTr("Volume")
                    right_text: atomic_qt_utilities.retrieve_main_ticker(left_ticker)
                    placeholderText: sell_mode ? qsTr("Amount to sell") : qsTr("Amount to receive")
                    text: API.app.trading_pg.volume
                    onTextChanged: setVolume(text)
                }

                DefaultText
                {
                    anchors.right: input_volume.right
                    anchors.top: input_volume.bottom
                    anchors.topMargin: price_usd_value.anchors.topMargin

                    text_value: General.getFiatText(non_null_volume, left_ticker)
                    font.pixelSize: input_volume.font.pixelSize
                    color: Dex.CurrentTheme.foregroundColor2

                    CexInfoTrigger {}
                }
            }

            DexRangeSlider
            {
                id: _volumeRange

                property real oldSecondValue: 0
                property real oldFirstValue: 0

                function getRealValue() { return first.position * (first.to - first.from); }

                function getRealValue2() { return second.position * (second.to - second.from); }

                enabled: input_volume.enabled && !(!sell_mode && General.isZero(non_null_price)) && to > 0

                Layout.preferredWidth: parent.width - 20

                rangeBackgroundColor: Qt.lighter(rangeDistanceColor)
                rangeDistanceColor: sell_mode ? DexTheme.redColor : DexTheme.greenColor
                from: API.app.trading_pg.orderbook.current_min_taker_vol
                to: Math.max(0, parseFloat(max_volume))

                first.value: parseFloat(API.app.trading_pg.min_trade_vol)

                firstDisabled: !_useCustomMinTradeAmountCheckbox.checked
                defaultFirstValue: parseFloat(API.app.trading_pg.min_trade_vol)

                firstTooltip.text: qsTr("Minimum volume: %1").arg(General.formatDouble(first.value, General.getRecommendedPrecision(second.value)))
                second.value: parseFloat(non_null_volume)
                secondTooltip.text: qsTr("Volume: %1").arg(General.formatDouble(second.value, General.getRecommendedPrecision(to)))

                first.onValueChanged: if (first.pressed) setMinimumAmount(General.formatDouble(first.value))
                second.onValueChanged: if (second.pressed) setVolume(General.formatDouble(second.value))
                second.onPressedChanged: if (second.pressed) oldSecondValue = second.value

                DefaultText
                {
                    anchors.left: parent.right
                    anchors.leftMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    text: General.cex_icon
                    color: Dex.CurrentTheme.foregroundColor3

                    DefaultMouseArea
                    {
                        anchors.fill: parent
                        onClicked: _sliderHelpModal.open()
                    }

                    ModalLoader
                    {
                        id: _sliderHelpModal
                        sourceComponent: HelpModal
                        {
                            title: qsTr("How to use the pro-view slider ?")
                            helpSentence: qsTr("This slider is used to setup the order requirements you need.\nLeft slider: Sets the minimum amount required to process a trade.\nRight slider: Sets the volume you want to trade.")
                        }
                    }
                }
            }

            DexCheckBox
            {
                id: _useCustomMinTradeAmountCheckbox

                Layout.topMargin: 15
                Layout.alignment: Qt.AlignHCenter
                Layout.fillWidth: true

                boxWidth: 20.76
                boxHeight: 20.76
                text: qsTr("Use custom minimum trade amount")
                textColor: Dex.CurrentTheme.foregroundColor3
                font.pixelSize: 13
                onPressed:
                {
                    if (!checked) _volumeRange.oldFirstValue = _volumeRange.defaultFirstValue;
                    else
                    {
                        _volumeRange.defaultFirstValue = API.app.trading_pg.orderbook.current_min_taker_vol;
                        _volumeRange.first.value = API.app.trading_pg.orderbook.current_min_taker_vol;
                    }
                }
            }
        }
    }
}
