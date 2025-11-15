"""
GE Vernova Building 37 - MIT Hackathon Data Analysis Toolkit
Author: Data Science Team Lead
Purpose: Analyze building usage patterns and identify sustainability opportunities
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from datetime import datetime
import warnings
warnings.filterwarnings('ignore')

# Set visualization style
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 6)

class Building37Analyzer:
    """Comprehensive analysis toolkit for GE Building 37 sustainability challenge"""
    
    def __init__(self):
        self.badge_data = None
        self.energy_data = None
        self.conference_data = None
        self.building_info = {
            'floors': 6,
            'floor_1_2_sqft': 44352,
            'floor_3_6_sqft': 22728,
            'total_sqft': 2 * 44352 + 4 * 22728,
            'employees': 356,
            'conference_rooms': ['Room 133', 'Room 128', 'Room 129', 'Room 130', 
                                'Room 131', 'Room 132', 'Room 135', 'Van Curler A', 
                                'Van Curler B', 'Schuyler', 'Glen', 'Van Buren', 
                                'Van Patten', 'Auditorium A', 'Auditorium B', 'Auditorium C']
        }
        
    def load_data(self, badge_path, energy_path, conference_path):
        """Load all datasets"""
        print("Loading datasets...")
        
        # Badge swipe data
        self.badge_data = pd.read_csv(badge_path, skiprows=1)  # Skip "Table 1" header
        print(f"✓ Badge data loaded: {len(self.badge_data)} employees")
        
        # Energy consumption data
        self.energy_data = pd.read_csv(energy_path, skiprows=4)
        self.energy_data.columns = self.energy_data.columns.str.strip()
        print(f"✓ Energy data loaded: {len(self.energy_data)} records")
        
        # Conference room usage
        self.conference_data = pd.read_csv(conference_path, skiprows=1)  # Skip "Table 1" header
        # Clean up the Date column (remove extra spaces)
        self.conference_data['Date'] = self.conference_data['Date'].str.strip()
        self.conference_data['Date'] = pd.to_datetime(self.conference_data['Date'], errors='coerce')
        # Remove rows with invalid dates
        self.conference_data = self.conference_data.dropna(subset=['Date'])
        print(f"✓ Conference data loaded: {len(self.conference_data)} bookings")
        
        return self
    
    def analyze_occupancy_patterns(self):
        """Analyze employee badge swipe patterns to identify occupancy trends"""
        print("\n" + "="*60)
        print("OCCUPANCY PATTERN ANALYSIS")
        print("="*60)
        
        # Calculate monthly occupancy
        months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep']
        
        # Total swipes per month
        monthly_swipes = self.badge_data[months].sum()
        
        # Average swipes per employee per month
        avg_swipes_per_employee = monthly_swipes / len(self.badge_data)
        
        # Assuming ~20 working days per month
        avg_days_in_office = avg_swipes_per_employee / 20
        
        print(f"\nMonthly Average In-Office Days per Employee:")
        for month, days in avg_days_in_office.items():
            print(f"  {month}: {days:.1f} days (~{days/4:.0f}% attendance)")
        
        # Floor-wise occupancy
        floor_occupancy = self.badge_data.groupby('Floor')[months].sum().sum(axis=1)
        
        print(f"\nTotal Swipes by Floor (Jan-Sep 2025):")
        for floor, swipes in floor_occupancy.items():
            pct = swipes / floor_occupancy.sum() * 100
            print(f"  Floor {floor}: {swipes:,} swipes ({pct:.1f}%)")
        
        # Identify low-utilization employees (potential remote workers)
        total_swipes = self.badge_data[months].sum(axis=1)
        low_util = total_swipes < 50  # Less than ~6 days/month average
        
        print(f"\nLow Utilization Insights:")
        print(f"  Employees with <50 swipes (likely remote): {low_util.sum()} ({low_util.sum()/len(self.badge_data)*100:.1f}%)")
        print(f"  Potential space reduction opportunity: {low_util.sum() * 150:.0f} sqft")
        
        return {
            'monthly_swipes': monthly_swipes,
            'avg_days_in_office': avg_days_in_office.mean(),
            'floor_distribution': floor_occupancy,
            'remote_workers': low_util.sum()
        }
    
    def analyze_energy_consumption(self):
        """Analyze energy, gas, and water consumption patterns"""
        print("\n" + "="*60)
        print("ENERGY CONSUMPTION ANALYSIS")
        print("="*60)
        
        # Annual totals
        total_electricity = 5_666_000  # kWh
        total_gas = 273_000  # CCF
        total_water = 129_777_000  # Gallons
        
        # Calculate per square foot metrics
        sqft = self.building_info['total_sqft']
        
        electricity_per_sqft = total_electricity / sqft
        gas_per_sqft = total_gas / sqft
        water_per_sqft = total_water / sqft
        
        print(f"\nAnnual Consumption Metrics:")
        print(f"  Total Electricity: {total_electricity:,} kWh")
        print(f"  Total Natural Gas: {total_gas:,} CCF")
        print(f"  Total Water: {total_water:,} gallons")
        print(f"\nPer Square Foot (181,616 sqft):")
        print(f"  Electricity: {electricity_per_sqft:.1f} kWh/sqft/yr")
        print(f"  Natural Gas: {gas_per_sqft:.2f} CCF/sqft/yr")
        print(f"  Water: {water_per_sqft:.1f} gal/sqft/yr")
        
        # Seasonal patterns
        months = ['January 2025', 'February 2025', 'March 2025', 'April 2025', 
                  'May 2025', 'June 2025', 'July 2025', 'August 2025', 'September 2025']
        
        electricity = [463000, 413000, 485000, 474000, 461000, 477000, 516000, 491000, 470000]
        gas = [48000, 41000, 35000, 23000, 14000, 12000, 8000, 11000, 12000]
        water = [5978000, 5901000, 6083000, 9405000, 9434000, 9405000, 17143000, 17287000, 16696000]
        
        print(f"\nSeasonal Insights:")
        print(f"  Peak electricity: July ({max(electricity):,} kWh) - Cooling load")
        print(f"  Peak gas: January ({max(gas):,} CCF) - Heating load")
        print(f"  Peak water: July-Sep ({np.mean(water[-3:]):,.0f} gal avg) - 2.8x spring usage")
        
        # CO2 emissions estimation
        # Electricity: ~0.92 lbs CO2/kWh (NY grid mix)
        # Natural gas: ~11.7 lbs CO2/CCF
        co2_electricity = total_electricity * 0.92 / 2000  # tons
        co2_gas = total_gas * 11.7 / 2000  # tons
        
        print(f"\nEstimated Annual CO2 Emissions:")
        print(f"  From Electricity: {co2_electricity:,.0f} tons")
        print(f"  From Natural Gas: {co2_gas:,.0f} tons")
        print(f"  Total: {co2_electricity + co2_gas:,.0f} tons CO2")
        
        return {
            'electricity_per_sqft': electricity_per_sqft,
            'total_co2_tons': co2_electricity + co2_gas,
            'water_surge': water[-3:],  # Summer months show 2.8x increase
            'heating_cooling_ratio': max(gas) / min(gas)
        }
    
    def analyze_conference_room_utilization(self):
        """Analyze conference room booking and actual usage patterns"""
        print("\n" + "="*60)
        print("CONFERENCE ROOM UTILIZATION ANALYSIS")
        print("="*60)
        
        # Filter 2025 data
        df_2025 = self.conference_data[self.conference_data['Date'].dt.year == 2025].copy()
        
        # Calculate hours booked
        df_2025['Start'] = pd.to_datetime(df_2025['Start'], format='%I:%M %p', errors='coerce')
        df_2025['Finish'] = pd.to_datetime(df_2025['Finish'], format='%I:%M %p', errors='coerce')
        df_2025['Hours'] = (df_2025['Finish'] - df_2025['Start']).dt.total_seconds() / 3600
        
        # Handle all-day bookings (12 AM to 12 AM or similar)
        df_2025.loc[df_2025['Hours'] < 0, 'Hours'] = 15  # Assume 15-hour events
        df_2025.loc[df_2025['Hours'] > 20, 'Hours'] = 15
        
        # Room utilization statistics
        room_stats = df_2025.groupby('Room').agg({
            'Date': 'count',
            '#Attendees': ['sum', 'mean'],
            'Hours': 'sum'
        }).round(1)
        
        room_stats.columns = ['Bookings', 'Total_Attendees', 'Avg_Attendees', 'Total_Hours']
        
        print(f"\nRoom Utilization (Jan-Sep 2025):")
        print(f"  Total Bookings: {len(df_2025)}")
        print(f"  Total Attendees: {df_2025['#Attendees'].sum():,.0f}")
        
        # Identify ghost bookings (0 attendees)
        ghost = df_2025['#Attendees'] == 0
        print(f"\n⚠️  Ghost Bookings (0 attendees): {ghost.sum()} ({ghost.sum()/len(df_2025)*100:.1f}%)")
        print(f"  Wasted Hours: {df_2025[ghost]['Hours'].sum():.0f} hours")
        
        # Booking type distribution
        print(f"\nBooking Types:")
        for booking_type, count in df_2025['Attendance Type'].value_counts().head(5).items():
            print(f"  {booking_type}: {count} bookings")
        
        # Underutilized rooms (high capacity, low average attendance)
        auditorium_bookings = df_2025[df_2025['Room'].str.contains('Auditorium')]
        avg_auditorium_attendance = auditorium_bookings['#Attendees'].mean()
        
        print(f"\nAuditorium Insights:")
        print(f"  Average Auditorium Attendance: {avg_auditorium_attendance:.1f} people")
        
        return {
            'total_bookings': len(df_2025),
            'ghost_bookings': ghost.sum(),
            'avg_auditorium_attendance': avg_auditorium_attendance
        }

if __name__ == "__main__":
    # Initialize analyzer
    analyzer = Building37Analyzer()
    
    # Load data with available CSV files
    badge_file = "Assumed Population in Future B37 Use - Badge Swipes YTD 2025.csv"
    energy_file = "FINAL MIT Hackathon Data - Schenectady.csv"
    conference_file = "GE 37 Conference Center usage JAN24-SEP25.csv"
    
    # Load and analyze data
    analyzer.load_data(badge_file, energy_file, conference_file)
    
    # Run all analyses
    occupancy_results = analyzer.analyze_occupancy_patterns()
    energy_results = analyzer.analyze_energy_consumption()
    conference_results = analyzer.analyze_conference_room_utilization()
    
    print("\n" + "="*60)
    print("ANALYSIS COMPLETE")
    print("="*60)
